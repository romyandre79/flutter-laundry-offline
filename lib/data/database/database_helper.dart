import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:kreatif_laundry_offline_app/core/constants/app_constants.dart';
import 'package:kreatif_laundry_offline_app/core/utils/password_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // Create Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT UNIQUE,
        address TEXT,
        notes TEXT,
        total_orders INTEGER DEFAULT 0,
        total_spent INTEGER DEFAULT 0,
        last_order_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Services table
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        unit TEXT NOT NULL,
        price INTEGER NOT NULL,
        duration_days INTEGER DEFAULT 3,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create Orders table
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT UNIQUE NOT NULL,
        customer_id INTEGER,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        order_date TEXT NOT NULL,
        due_date TEXT,
        status TEXT NOT NULL,
        total_items INTEGER DEFAULT 0,
        total_weight REAL DEFAULT 0,
        total_price INTEGER NOT NULL,
        paid INTEGER DEFAULT 0,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Create Order Items table
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        service_id INTEGER,
        service_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        price_per_unit INTEGER NOT NULL,
        subtotal INTEGER NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL
      )
    ''');

    // Create Order Images table
    await db.execute('''
      CREATE TABLE order_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    // Create Payments table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        change INTEGER DEFAULT 0,
        payment_date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        notes TEXT,
        received_by INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (received_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Create App Settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes
    await _createIndexes(db);

    // Seed default data
    await _seedData(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Users indexes
    await db.execute('CREATE INDEX idx_users_username ON users(username)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');

    // Customers indexes
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');

    // Orders indexes
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
    await db.execute('CREATE INDEX idx_orders_date ON orders(order_date)');
    await db.execute('CREATE INDEX idx_orders_invoice ON orders(invoice_no)');
    await db.execute('CREATE INDEX idx_orders_customer ON orders(customer_id)');

    // Order Items indexes
    await db.execute('CREATE INDEX idx_order_items_order ON order_items(order_id)');
    
    // Order Images indexes
    await db.execute('CREATE INDEX idx_order_images_order ON order_images(order_id)');

    // Payments indexes
    await db.execute('CREATE INDEX idx_payments_order ON payments(order_id)');
    await db.execute('CREATE INDEX idx_payments_date ON payments(payment_date)');
  }

  Future<void> _seedData(Database db) async {
    // Seed default owner
    final passwordHash = PasswordHelper.hashPassword(AppConstants.defaultOwnerPassword);
    await db.insert('users', {
      'username': AppConstants.defaultOwnerUsername,
      'password_hash': passwordHash,
      'name': AppConstants.defaultOwnerName,
      'role': 'owner',
      'is_active': 1,
    });

    // Seed default services
    final services = [
      {'name': 'Cuci Kering', 'unit': 'kg', 'price': 8000, 'duration_days': 3},
      {'name': 'Cuci Setrika', 'unit': 'kg', 'price': 10000, 'duration_days': 3},
      {'name': 'Setrika Saja', 'unit': 'kg', 'price': 5000, 'duration_days': 2},
      {'name': 'Cuci Bed Cover', 'unit': 'pcs', 'price': 25000, 'duration_days': 4},
      {'name': 'Cuci Karpet', 'unit': 'pcs', 'price': 35000, 'duration_days': 5},
      {'name': 'Cuci Boneka', 'unit': 'pcs', 'price': 15000, 'duration_days': 3},
    ];

    for (final service in services) {
      await db.insert('services', {
        ...service,
        'is_active': 1,
      });
    }

    // Seed default settings
    final settings = {
      AppConstants.keyLaundryName: AppConstants.defaultLaundryName,
      AppConstants.keyLaundryAddress: AppConstants.defaultLaundryAddress,
      AppConstants.keyLaundryPhone: AppConstants.defaultLaundryPhone,
      AppConstants.keyInvoicePrefix: AppConstants.defaultInvoicePrefix,
      AppConstants.keyPrinterAddress: '',
      AppConstants.keyLastInvoiceDate: '',
      AppConstants.keyLastInvoiceNumber: '0',
    };

    for (final entry in settings.entries) {
      await db.insert('app_settings', {
        'key': entry.key,
        'value': entry.value,
      });
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here
    if (oldVersion < 2) {
      // Add change column to payments table
      await db.execute('ALTER TABLE payments ADD COLUMN change INTEGER DEFAULT 0');
    }

    if (oldVersion < 3) {
      // Create Order Images table
      await db.execute('''
        CREATE TABLE order_images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          order_id INTEGER NOT NULL,
          image_path TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_order_images_order ON order_images(order_id)');
    }
  }

  // Utility methods
  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  Future<void> resetDatabase() async {
    await deleteDatabase();
    await database; // This will recreate the database
  }
}
