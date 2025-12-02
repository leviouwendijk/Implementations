import SwiftUI
@preconcurrency import Contacts
import Combine
import Interfaces
import plate
import Structures

@MainActor
public class ContactsListViewModel: ObservableObject {
    @Published public var isLoading = false
    @Published public var errorMessage: String?

    @Published public var contacts: [CNContact] = []
    @Published public var searchQuery: String = ""
    @Published public var searchStrictness: SearchStrictness = .strict 

    @Published public private(set) var filteredContacts: [CNContact] = []

    @Published public var isFuzzyFiltering = false

    @Published public var selectedContactId: String? = nil
    @Published public var scrollToFirstID: String? = nil

    private var pendingFilterWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.2

    private var debounceFilterTask: Task<Void, Never>? = nil

    // public init() {
    //     Task { 
    //         await loadAllContacts()
    //     }
    //     fuzzyFilterListener()
    // }

    // public func loadAllContacts() async {
    //     // DispatchQueue.main.async {
    //         self.isLoading = true
    //         self.errorMessage = nil
    //     // }
    //     do {
    //         let fetched = try await loadContacts()
    //         // DispatchQueue.main.async {
    //             print("[ContactsVM] assigning contacts (\(fetched.count) items)")
    //             self.contacts = fetched
    //             self.isLoading = false
    //         // }
    //     } catch {
    //         // DispatchQueue.main.async {
    //             self.errorMessage = error.localizedDescription
    //             self.isLoading = false
    //         // }
    //     }
    //     // isLoading = false
    // }

    // private var cancellables = Set<AnyCancellable>()

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

    public func resetSelectedContact() {
        self.selectedContactId = nil
    }


    // NEW CONCURRENCY IMPLEMENTATION
    public init() {
        // Task { await loadAllContacts() }
        // startFiltering()
    }

    public func loadAllContacts() {
        // We are on the main actor here.
        isLoading = true
        errorMessage = nil

        let vm = self

        Task.detached(priority: .userInitiated) { [weak vm] in
            guard let vm = vm else { return }

            do {
                // Heavy work off-main
                let all = try fetchContacts()
                print("[ContactsVM] fetched \(all.count) contacts")

                // Let anything currently in the runloop finish
                await Task.yield()

                // Hop back to the main actor from this *separate* task
                await MainActor.run {
                    vm.contacts = all
                    vm.filteredContacts = all
                    vm.isLoading = false
                }
            } catch {
                await MainActor.run {
                    vm.errorMessage = error.localizedDescription
                    vm.isLoading = false
                }
            }
        }
    }

    // public func loadAllContacts() async {
    //     await MainActor.run {
    //         self.isLoading = true
    //         self.errorMessage = nil
    //     }
    //     do {
    //         let all = try await withCheckedThrowingContinuation { cont in
    //             DispatchQueue.global(qos: .userInitiated).async {
    //                 do {
    //                     let fetched = try fetchContacts()
    //                     cont.resume(returning: fetched)
    //                 } catch {
    //                     cont.resume(throwing: error)
    //                 }
    //             }
    //         }
    //         await MainActor.run {
    //             self.contacts = all
    //             self.filteredContacts = all  // new assign
    //             self.isLoading = false
    //         }
    //     } catch {
    //         await MainActor.run {
    //             self.errorMessage = error.localizedDescription
    //             self.isLoading = false
    //         }
    //     }
    // }

    private var filterTask: Task<Void, Never>?

    public func startFiltering() {
        filterTask?.cancel()
        filterTask = Task { [weak self] in
            guard let self = self else { return }

            let updates = Publishers
                .CombineLatest3(self.$contacts, self.$searchQuery, self.$searchStrictness)
                .drop { $0.0.isEmpty }
                .removeDuplicates { a, b in
                   a.0.count == b.0.count && a.1 == b.1 && a.2 == b.2
                }
                .debounce(
                   for: .milliseconds(200),
                   scheduler: DispatchQueue.global(qos: .userInitiated)
                )
                .values

            for await (allContacts, query, strictness) in updates {
                if Task.isCancelled { break }

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        self.isFuzzyFiltering = true
                    }
                }

                let results: [CNContact] = await withCheckedContinuation { cont in
                    DispatchQueue.global(qos: .userInitiated).async {
                        let filtered = allContacts.filteredClientContacts(
                            matching: query.normalizedForClientDogSearch,
                            fuzzyTolerance: strictness.tolerance
                        )
                        cont.resume(returning: filtered)
                    }
                }
                if Task.isCancelled { break }

                await Task.yield()

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.isFuzzyFiltering = false
                        self.filteredContacts = results
                    }
                    self.scrollToFirstID = results.first?.identifier
                }
            }
        }
    }

    deinit {
        filterTask?.cancel()
    }

    public func reloadContacts() {
        // Task { await loadAllContacts() }
        loadAllContacts() 
    }
}
