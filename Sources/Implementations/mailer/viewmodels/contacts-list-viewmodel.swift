import SwiftUI
@preconcurrency import Contacts
import Combine
import Interfaces
import plate
import Structures

@MainActor
public class ContactsListViewModel: ObservableObject {
    // @Published public var contacts: [CNContact] = []
    // @Published public var searchQuery: String = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    // @Published public var searchStrictness: SearchStrictness = .strict

    @Published public var contacts: [CNContact] = [] {
        didSet { scheduleFilterIfNeeded() }
    }
    @Published public var searchQuery: String = "" {
        didSet { scheduleFilterIfNeeded() }
    }
    @Published public var searchStrictness: SearchStrictness = .strict {
        didSet { scheduleFilterIfNeeded() }
    }

    // @Published public private(set) var filteredContacts: [CNContact] = []
    @Published public private(set) var filteredContacts: [CNContact] = []

    @Published public var isFuzzyFiltering = false

    @Published public var selectedContactId: String? = nil
    // @Published public var scrollToFirstID: String? = nil

    private var pendingFilterWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.2

    private var debounceFilterTask: Task<Void, Never>? = nil

    public init() {
        Task { 
            await loadAllContacts()
        }
        // fuzzyFilterListener()
    }

    public func loadAllContacts() async {
        // DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        // }
        do {
            let fetched = try await loadContacts()
            // DispatchQueue.main.async {
                print("[ContactsVM] assigning contacts (\(fetched.count) items)")
                self.contacts = fetched
                self.isLoading = false
            // }
        } catch {
            // DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            // }
        }
        // isLoading = false
    }

    private var cancellables = Set<AnyCancellable>()

    // public func fuzzyFilterListener() {
    //     Publishers
    //     .CombineLatest3($contacts, $searchQuery, $searchStrictness)
    //     .drop { contacts, _, _ in contacts.isEmpty }
    //     .removeDuplicates(by: { a, b in
    //         return a.0.count == b.0.count
    //         && a.1 == b.1
    //         && a.2 == b.2
    //     })
    //     .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
    //     .sink { [weak self] allContacts, query, strictness in
    //         guard let self = self else { return }

    //         if !(self.isLoading) {
    //             withAnimation(.easeInOut(duration: 0.25)) {
    //                 self.isFuzzyFiltering = true
    //             }
    //         }

    //         self.applyFuzzyFilter(
    //             to: allContacts,
    //             query: query,
    //             tolerance: strictness.tolerance
    //         )
    //     }
    //     .store(in: &cancellables)
    // }

    // public func applyFuzzyFilter(
    //     to allContacts: [CNContact],
    //     query: String,
    //     tolerance: Int
    // ) {
    //     let normalized = query.normalizedForClientDogSearch

    //     DispatchQueue.global(qos: .userInitiated).async {
    //         let results = allContacts
    //         .filteredClientContacts(
    //             matching: normalized,
    //             fuzzyTolerance: tolerance
    //         )

    //         DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
    //             withAnimation(.easeInOut(duration: 0.20)) {
    //                 self.filteredContacts = results
    //                 self.isFuzzyFiltering = false
    //             }
    //             // self.scrollToFirstID = results.first?.identifier
    //         }
    //     }
    // }

    private func scheduleFilterIfNeeded() {
        guard !contacts.isEmpty else {
            return
        }

        debounceFilterTask?.cancel()

        let snapshotContacts   = self.contacts
        let snapshotQuery      = self.searchQuery
        let snapshotStrictness = self.searchStrictness

        if !isLoading {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.isFuzzyFiltering = true
            }
        }

        debounceFilterTask = Task { [weak self] in
            guard let self = self else { return }

            try? await Task.sleep(nanoseconds: UInt64(self.debounceInterval * 1_000_000_000))

            guard !Task.isCancelled else { return }

            let results = await self.filterContacts(
                allContacts: snapshotContacts,
                query:       snapshotQuery,
                tolerance:   snapshotStrictness.tolerance
            )

            guard !Task.isCancelled else { return }

            self.filteredContacts = results

            // let newFirstID = results.first?.identifier
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.20)) {
                    self.isFuzzyFiltering = false
                }
                // self.scrollToFirstID = newFirstID
            }
        }
    }

    @Sendable
    private func filterContacts(
        allContacts: [CNContact],
        query: String,
        tolerance: Int
    ) async -> [CNContact] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let normalized = query.normalizedForClientDogSearch
                let results = allContacts.filteredClientContacts(
                    matching: normalized,
                    fuzzyTolerance: tolerance
                )
                continuation.resume(returning: results)
            }
        }
    }
}
