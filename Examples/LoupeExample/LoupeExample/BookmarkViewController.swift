import UIKit

struct BookmarkItem {
    let id: String
    var title: String
    var url: String
    var category: String
    var isFavorite: Bool
    var notes: String
}

final class BookmarkStore {
    private(set) var bookmarks: [BookmarkItem] = [
        BookmarkItem(
            id: "swift",
            title: "Swift Documentation",
            url: "https://www.swift.org/documentation",
            category: "Docs",
            isFavorite: true,
            notes: "Language reference and package manager guides."
        ),
        BookmarkItem(
            id: "hig",
            title: "Human Interface Guidelines",
            url: "https://developer.apple.com/design/human-interface-guidelines",
            category: "Design",
            isFavorite: false,
            notes: "UIKit and platform interaction guidance."
        ),
        BookmarkItem(
            id: "webkit",
            title: "WebKit Blog",
            url: "https://webkit.org/blog",
            category: "Web",
            isFavorite: false,
            notes: "Web engine updates and implementation notes."
        ),
    ]

    var favorites: [BookmarkItem] {
        bookmarks.filter(\.isFavorite)
    }

    func add(_ bookmark: BookmarkItem) {
        bookmarks.insert(bookmark, at: 0)
    }

    func updateFavorite(id: String, isFavorite: Bool) {
        guard let index = bookmarks.firstIndex(where: { $0.id == id }) else {
            return
        }
        bookmarks[index].isFavorite = isFavorite
    }

    func search(_ query: String) -> [BookmarkItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return bookmarks
        }

        return bookmarks.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.url.localizedCaseInsensitiveContains(trimmed)
                || $0.category.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

final class BookmarkTabController: UITabBarController {
    private let store = BookmarkStore()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityIdentifier = "bookmark.tabs"
        tabBar.accessibilityIdentifier = "bookmark.tabbar"

        let list = BookmarkListViewController(store: store)
        let favorites = BookmarkFavoritesViewController(store: store)
        let search = BookmarkSearchViewController(store: store)

        viewControllers = [
            embed(list, title: "List", image: "book", identifier: "bookmark.tab.list"),
            embed(favorites, title: "Favorites", image: "star", identifier: "bookmark.tab.favorites"),
            embed(search, title: "Search", image: "magnifyingglass", identifier: "bookmark.tab.search"),
        ]
    }

    private func embed(
        _ viewController: UIViewController,
        title: String,
        image: String,
        identifier: String
    ) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: image),
            selectedImage: UIImage(systemName: image)
        )
        navigationController.tabBarItem.accessibilityIdentifier = identifier
        return navigationController
    }
}

final class BookmarkListViewController: UITableViewController {
    private let store: BookmarkStore

    init(store: BookmarkStore) {
        self.store = store
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Bookmarks"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addBookmark)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "bookmark.add"

        tableView.register(BookmarkCell.self, forCellReuseIdentifier: BookmarkCell.reuseIdentifier)
        tableView.rowHeight = 78
        view.accessibilityIdentifier = "bookmark.list"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        store.bookmarks.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BookmarkCell.reuseIdentifier,
            for: indexPath
        ) as! BookmarkCell
        cell.configure(bookmark: store.bookmarks[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let bookmark = store.bookmarks[indexPath.row]
        navigationController?.pushViewController(
            BookmarkDetailViewController(bookmark: bookmark) { [weak self] isFavorite in
                self?.store.updateFavorite(id: bookmark.id, isFavorite: isFavorite)
            },
            animated: true
        )
    }

    @objc private func addBookmark() {
        navigationController?.pushViewController(
            BookmarkEditorViewController { [weak self] bookmark in
                guard let self else { return }
                self.store.add(bookmark)
            },
            animated: true
        )
    }
}

final class BookmarkFavoritesViewController: UITableViewController {
    private let store: BookmarkStore
    private var favoriteBookmarks: [BookmarkItem] = []

    init(store: BookmarkStore) {
        self.store = store
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Favorites"
        navigationItem.largeTitleDisplayMode = .always
        tableView.register(BookmarkCell.self, forCellReuseIdentifier: BookmarkCell.reuseIdentifier)
        tableView.rowHeight = 78
        view.accessibilityIdentifier = "bookmark.favorites"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        favoriteBookmarks = store.favorites
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favoriteBookmarks.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BookmarkCell.reuseIdentifier,
            for: indexPath
        ) as! BookmarkCell
        cell.configure(bookmark: favoriteBookmarks[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let bookmark = favoriteBookmarks[indexPath.row]
        navigationController?.pushViewController(
            BookmarkDetailViewController(bookmark: bookmark) { [weak self] isFavorite in
                self?.store.updateFavorite(id: bookmark.id, isFavorite: isFavorite)
            },
            animated: true
        )
    }
}

final class BookmarkSearchViewController: UITableViewController {
    private let store: BookmarkStore
    private let searchBar = UISearchBar(frame: .zero)
    private var results: [BookmarkItem] = []

    init(store: BookmarkStore) {
        self.store = store
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search"
        navigationItem.largeTitleDisplayMode = .always
        tableView.register(BookmarkCell.self, forCellReuseIdentifier: BookmarkCell.reuseIdentifier)
        tableView.rowHeight = 78
        view.accessibilityIdentifier = "bookmark.search"

        searchBar.placeholder = "Search bookmarks"
        searchBar.accessibilityIdentifier = "bookmark.search.field"
        searchBar.delegate = self
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar

        results = store.search("")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applySearch()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BookmarkCell.reuseIdentifier,
            for: indexPath
        ) as! BookmarkCell
        cell.configure(bookmark: results[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let bookmark = results[indexPath.row]
        navigationController?.pushViewController(
            BookmarkDetailViewController(bookmark: bookmark) { [weak self] isFavorite in
                self?.store.updateFavorite(id: bookmark.id, isFavorite: isFavorite)
            },
            animated: true
        )
    }

    private func applySearch() {
        results = store.search(searchBar.text ?? "")
        tableView.reloadData()
    }
}

extension BookmarkSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySearch()
    }
}

final class BookmarkCell: UITableViewCell {
    static let reuseIdentifier = "BookmarkCell"

    private let titleLabel = UILabel()
    private let urlLabel = UILabel()
    private let categoryLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        configureLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(bookmark: BookmarkItem) {
        accessibilityIdentifier = "bookmark.item.\(bookmark.id)"
        titleLabel.accessibilityIdentifier = "bookmark.item.\(bookmark.id).title"
        urlLabel.accessibilityIdentifier = "bookmark.item.\(bookmark.id).url"
        categoryLabel.accessibilityIdentifier = "bookmark.item.\(bookmark.id).category"

        titleLabel.text = bookmark.title
        urlLabel.text = bookmark.url
        categoryLabel.text = bookmark.isFavorite ? "\(bookmark.category) *" : bookmark.category
        accessibilityLabel = "\(bookmark.title), \(bookmark.category)"
        accessibilityHint = "Open bookmark details"
        isAccessibilityElement = true
    }

    private func configureLayout() {
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        urlLabel.font = .preferredFont(forTextStyle: .subheadline)
        urlLabel.textColor = .secondaryLabel
        categoryLabel.font = .preferredFont(forTextStyle: .caption1)
        categoryLabel.textColor = .systemBlue

        let stack = UIStackView(arrangedSubviews: [titleLabel, urlLabel, categoryLabel])
        stack.axis = .vertical
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
}

final class BookmarkDetailViewController: UIViewController {
    private let bookmark: BookmarkItem
    private let onFavoriteChanged: (Bool) -> Void
    private let titleLabel = UILabel()
    private let urlLabel = UILabel()
    private let favoriteSwitch = UISwitch()
    private let favoriteButton = UIButton(type: .system)
    private let notesView = UITextView()
    private let categoryControl = UISegmentedControl(items: ["Docs", "Design", "Web"])

    init(bookmark: BookmarkItem, onFavoriteChanged: @escaping (Bool) -> Void) {
        self.bookmark = bookmark
        self.onFavoriteChanged = onFavoriteChanged
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Bookmark"
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "bookmark.detail"
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(pop)
        )
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "bookmark.detail.back"
        configureControls()
        configureLayout()
    }

    private func configureControls() {
        titleLabel.text = bookmark.title
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityIdentifier = "bookmark.detail.title"

        urlLabel.text = bookmark.url
        urlLabel.font = .preferredFont(forTextStyle: .body)
        urlLabel.textColor = .secondaryLabel
        urlLabel.numberOfLines = 0
        urlLabel.accessibilityIdentifier = "bookmark.detail.url"

        favoriteSwitch.isOn = bookmark.isFavorite
        favoriteSwitch.accessibilityIdentifier = "bookmark.detail.favorite"
        favoriteSwitch.addTarget(self, action: #selector(favoriteChanged), for: .valueChanged)

        favoriteButton.setTitle("Toggle", for: .normal)
        favoriteButton.accessibilityIdentifier = "bookmark.detail.favorite.toggle"
        favoriteButton.addTarget(self, action: #selector(toggleFavorite), for: .touchUpInside)

        categoryControl.selectedSegmentIndex = ["Docs", "Design", "Web"].firstIndex(of: bookmark.category) ?? 0
        categoryControl.accessibilityIdentifier = "bookmark.detail.category"

        notesView.text = bookmark.notes
        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.layer.borderColor = UIColor.separator.cgColor
        notesView.layer.borderWidth = 1
        notesView.layer.cornerRadius = 8
        notesView.accessibilityIdentifier = "bookmark.detail.notes"
    }

    private func configureLayout() {
        let favoriteRow = UIStackView(arrangedSubviews: [makeLabel("Favorite"), favoriteSwitch, favoriteButton])
        favoriteRow.axis = .horizontal
        favoriteRow.alignment = .center
        favoriteRow.spacing = 12
        favoriteRow.accessibilityIdentifier = "bookmark.detail.favoriteRow"

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            urlLabel,
            favoriteRow,
            categoryControl,
            notesView,
        ])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            notesView.heightAnchor.constraint(equalToConstant: 160),
        ])
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }

    @objc private func pop() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func favoriteChanged() {
        onFavoriteChanged(favoriteSwitch.isOn)
    }

    @objc private func toggleFavorite() {
        favoriteSwitch.setOn(!favoriteSwitch.isOn, animated: true)
        onFavoriteChanged(favoriteSwitch.isOn)
    }
}

final class BookmarkEditorViewController: UIViewController {
    private let onSave: (BookmarkItem) -> Void
    private let titleField = UITextField()
    private let urlField = UITextField()
    private let favoriteSwitch = UISwitch()

    init(onSave: @escaping (BookmarkItem) -> Void) {
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Bookmark"
        view.backgroundColor = .systemBackground
        view.accessibilityIdentifier = "bookmark.editor"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(save)
        )
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "bookmark.editor.save"
        configureControls()
        configureLayout()
    }

    private func configureControls() {
        titleField.placeholder = "Title"
        titleField.borderStyle = .roundedRect
        titleField.accessibilityIdentifier = "bookmark.editor.title"

        urlField.placeholder = "URL"
        urlField.text = "https://example.com"
        urlField.keyboardType = .URL
        urlField.borderStyle = .roundedRect
        urlField.accessibilityIdentifier = "bookmark.editor.url"

        favoriteSwitch.isOn = true
        favoriteSwitch.accessibilityIdentifier = "bookmark.editor.favorite"
    }

    private func configureLayout() {
        let favoriteRow = UIStackView(arrangedSubviews: [makeLabel("Favorite"), favoriteSwitch])
        favoriteRow.axis = .horizontal
        favoriteRow.alignment = .center
        favoriteRow.distribution = .equalSpacing
        favoriteRow.accessibilityIdentifier = "bookmark.editor.favoriteRow"

        let stack = UIStackView(arrangedSubviews: [titleField, urlField, favoriteRow])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleField.heightAnchor.constraint(equalToConstant: 44),
            urlField.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        return label
    }

    @objc private func save() {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let bookmark = BookmarkItem(
            id: "created",
            title: title?.isEmpty == false ? title! : "Untitled Bookmark",
            url: urlField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "https://example.com",
            category: "Docs",
            isFavorite: favoriteSwitch.isOn,
            notes: "Created from the bookmark E2E fixture."
        )
        onSave(bookmark)
        navigationController?.popViewController(animated: true)
    }
}
