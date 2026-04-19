import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kreatif_laundry_offline_app/presentation/screens/common/windows_camera_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kreatif_laundry_offline_app/core/constants/colors.dart';
import 'package:kreatif_laundry_offline_app/core/theme/app_theme.dart';
import 'package:kreatif_laundry_offline_app/core/utils/currency_formatter.dart';
import 'package:kreatif_laundry_offline_app/core/utils/thousand_separator_formatter.dart';
import 'package:kreatif_laundry_offline_app/data/models/customer.dart';
import 'package:kreatif_laundry_offline_app/data/models/order_item.dart';
import 'package:kreatif_laundry_offline_app/data/models/payment.dart';
import 'package:kreatif_laundry_offline_app/data/models/service.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/auth/auth_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/customer/customer_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/order/order_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/order/order_state.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_cubit.dart';
import 'package:kreatif_laundry_offline_app/logic/cubits/service/service_state.dart';

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentController = TextEditingController();
  final _serviceSearchController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isLoading = false;
  int _orderDiscount = 0;

  // Selected customer
  Customer? _selectedCustomer;

  // Order items
  final List<_OrderItemEntry> _items = [];
  
  // Images
  final List<XFile> _capturedImages = [];
  final ImagePicker _picker = ImagePicker();

  int get _totalPrice {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  int get _netPrice => _totalPrice - _orderDiscount;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _paymentController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
  }

  void _toggleItem(Service service) {
    setState(() {
      final existing = _items.indexWhere((e) => e.service.id == service.id);
      if (existing >= 0) {
        // Sudah ada, hapus dari list
        _items.removeAt(existing);
      } else {
        // Belum ada, tambahkan
        final item = _OrderItemEntry(service: service);
        if (_selectedCustomer != null) {
          item.discount = ((service.price * _selectedCustomer!.defaultDiscount) / 100).round();
          item.updateSubtotal();
        }
        _items.add(item);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItemQuantity(int index, double quantity) {
    setState(() {
      _items[index].quantity = quantity;
      _items[index].updateSubtotal();
    });
  }

  void _showQuantityInputDialog(int index, _OrderItemEntry item) {
    final isKg = item.service.unit == ServiceUnit.kg;
    final controller = TextEditingController(text: item.quantityDisplay);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Masukkan Jumlah',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.service.name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppThemeColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: isKg
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              decoration: InputDecoration(
                suffixText: item.service.unit.value,
                hintText: isKg ? 'Contoh: 1.5' : 'Contoh: 3',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) {
                _submitQuantityInput(dialogContext, controller.text, index, item);
              },
            ),
            if (isKg)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bisa desimal, contoh: 0.5, 1.5, 2.3',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppThemeColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppThemeColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _submitQuantityInput(dialogContext, controller.text, index, item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _submitQuantityInput(
      BuildContext dialogContext, String input, int index, _OrderItemEntry item) {
    final isKg = item.service.unit == ServiceUnit.kg;
    // Replace comma with dot for decimal parsing
    final normalizedInput = input.replaceAll(',', '.');
    final parsed = double.tryParse(normalizedInput);

    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah yang valid'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    double finalQuantity;
    if (isKg) {
      // For kg: allow decimal, round to 1 decimal place
      finalQuantity = double.parse(parsed.toStringAsFixed(1));
    } else {
      // For pcs: only integer
      finalQuantity = parsed.roundToDouble();
    }

    Navigator.pop(dialogContext);
    _updateItemQuantity(index, finalQuantity);
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickImage() async {
    try {
      if (Platform.isWindows) {
        final XFile? photo = await Navigator.push<XFile?>(
          context,
          MaterialPageRoute(
            builder: (context) => const WindowsCameraScreen(),
          ),
        );
        
        if (photo != null) {
          setState(() {
            _capturedImages.add(photo);
          });
        }
        return;
      }
      
      // Fallback/Standard logic for other platforms
      final isDesktop = !Platform.isAndroid && !Platform.isIOS;
      final source = isDesktop ? ImageSource.gallery : ImageSource.camera;

      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Compress to save space
      );
      
      if (photo != null) {
        setState(() {
          _capturedImages.add(photo);
        });
      }
    } catch (e) {
      // Fallback try: if camera fails (e.g. no camera), try gallery
      if (e.toString().contains('camera') || e.toString().contains('delegate')) {
        try {
           final XFile? photo = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 50,
          );
          if (photo != null) {
            setState(() {
              _capturedImages.add(photo);
            });
          }
          return;
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _customerNameController.text = customer.name;
      _customerPhoneController.text = customer.phone ?? '';

      // Apply default discount to all items
      for (var item in _items) {
        item.discount = ((item.service.price * customer.defaultDiscount) / 100).round();
        item.updateSubtotal();
      }
    });
  }

  void _clearSelectedCustomer() {
    setState(() {
      _selectedCustomer = null;
      _customerNameController.clear();
      _customerPhoneController.clear();

      // Reset discount for all items
      for (var item in _items) {
        item.discount = 0;
        item.updateSubtotal();
      }
      _orderDiscount = 0;
    });
  }

  void _showCustomerSearchDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => BlocProvider.value(
        value: context.read<CustomerCubit>()..loadCustomers(),
        child: _CustomerSearchSheet(
          onCustomerSelected: (customer) {
            Navigator.pop(bottomSheetContext);
            _selectCustomer(customer);
          },
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 layanan'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final payment = ThousandSeparatorFormatter.parseToInt(_paymentController.text);

    // Jika bayar lebih dari total, tampilkan dialog konfirmasi kembalian
    if (payment > _netPrice) {
      _showChangeConfirmationDialog(payment);
    } else {
      _submitOrder(payment);
    }
  }

  void _showChangeConfirmationDialog(int payment) {
    final change = payment - _netPrice;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppThemeColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: AppThemeColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Konfirmasi Pembayaran',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppThemeColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildPaymentRow('Total Harus Bayar', CurrencyFormatter.format(_netPrice)),
                  const SizedBox(height: 8),
                  _buildPaymentRow('Bayar', CurrencyFormatter.format(payment)),
                  const Divider(height: 16),
                  _buildPaymentRow(
                    'Kembalian',
                    CurrencyFormatter.format(change),
                    valueColor: AppThemeColors.success,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pembayaran akan dicatat sebagai LUNAS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppThemeColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppThemeColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _submitOrder(payment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Konfirmasi',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppThemeColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _submitOrder(int payment) {
    final authState = context.read<AuthCubit>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : null;

    final orderItems = _items
        .map((e) => OrderItem(
              orderId: 0,
              serviceId: e.service.id,
              serviceName: e.service.name,
              quantity: e.quantity.toDouble(),
              unit: e.service.unit.value,
              pricePerUnit: e.service.price,
              discount: e.discount,
              subtotal: e.subtotal,
            ))
        .toList();

    context.read<OrderCubit>().createOrder(
          customerName: _customerNameController.text,
          customerPhone: _customerPhoneController.text.isNotEmpty
              ? _customerPhoneController.text
              : null,
          customerId: _selectedCustomer?.id,
          items: orderItems,
          dueDate: _dueDate,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          createdBy: userId,
          initialPayment: payment,
          paymentMethod: _paymentMethod,
          totalDiscount: _orderDiscount,
          images: _capturedImages.map((e) => e.path).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderLoading) {
          setState(() => _isLoading = true);
        } else {
          setState(() => _isLoading = false);
        }

        if (state is OrderCreated) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order ${state.order.invoiceNo} berhasil dibuat'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Baru'),
        ),
        bottomNavigationBar: _buildSummaryPanel(),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Customer Section
              _buildSectionTitle('Informasi Pelanggan'),
              const SizedBox(height: 12),

              // Customer selection card
              if (_selectedCustomer != null) ...[
                _buildSelectedCustomerCard(),
                const SizedBox(height: 12),
              ] else ...[
                // Search existing customer button
                InkWell(
                  onTap: _showCustomerSearchDialog,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppThemeColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppThemeColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppThemeColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_search,
                            color: AppThemeColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Pelanggan',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: AppThemeColors.primary,
                                ),
                              ),
                              Text(
                                'Cari dari daftar pelanggan',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppThemeColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppThemeColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Divider with "atau"
                Row(
                  children: [
                    Expanded(child: Divider(color: AppThemeColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'atau input manual',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppThemeColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppThemeColors.border)),
                  ],
                ),

                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan *',
                  prefixIcon: const Icon(Icons.person_outline),
                  enabled: _selectedCustomer == null,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _customerPhoneController,
                decoration: InputDecoration(
                  labelText: 'No. HP (Opsional)',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  hintText: '08xx-xxxx-xxxx',
                  enabled: _selectedCustomer == null,
                ),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Services Section
              _buildSectionTitle('Pilih Layanan'),
              const SizedBox(height: 12),
              _buildServiceSelector(),

              const SizedBox(height: 16),

              // Selected Items
              if (_items.isNotEmpty) ...[
                _buildSectionTitle('Item Dipilih'),
                const SizedBox(height: 12),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildItemCard(index, item);
                }),
              ],

              const SizedBox(height: 24),

              // Due Date
              _buildSectionTitle('Tanggal Ambil'),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppThemeColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppThemeColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Photos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Foto Laundry'),
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: AppThemeColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_capturedImages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada foto',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _capturedImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_capturedImages[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // Notes
              _buildSectionTitle('Catatan (Opsional)'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              // Payment Section
              _buildSectionTitle('Pembayaran'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _paymentController,
                      decoration: const InputDecoration(
                        labelText: 'Bayar (DP/Lunas)',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [ThousandSeparatorFormatter()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<PaymentMethod>(
                      initialValue: _paymentMethod,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Metode',
                      ),
                      items: PaymentMethod.values.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(
                            method.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _paymentMethod = v);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Total & Submit
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppThemeColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_totalPrice),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppThemeColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Buat Order',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSelectedCustomerCard() {
    final customer = _selectedCustomer!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemeColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppThemeColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.person,
              color: AppThemeColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppThemeColors.textPrimary,
                  ),
                ),
                if (customer.phone != null && customer.phone!.isNotEmpty)
                  Text(
                    customer.phone!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppThemeColors.textSecondary,
                    ),
                  ),
                if (customer.totalOrders > 0)
                  Text(
                    '${customer.totalOrders} order sebelumnya',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppThemeColors.success,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearSelectedCustomer,
            icon: Icon(
              Icons.close,
              color: AppThemeColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Hapus pilihan',
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector() {
    return BlocBuilder<ServiceCubit, ServiceState>(
      builder: (context, state) {
        final allServices = context.read<ServiceCubit>().services;
        final query = _serviceSearchController.text.toLowerCase();
        final services = allServices.where((s) {
          return s.name.toLowerCase().contains(query) || 
                 (s.barcode != null && s.barcode!.toLowerCase().contains(query));
        }).toList();

        if (allServices.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppThemeColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.local_laundry_service_outlined,
                    size: 40,
                    color: AppThemeColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada layanan',
                    style: GoogleFonts.poppins(
                      color: AppThemeColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Tambah layanan di menu Settings',
                    style: GoogleFonts.poppins(
                      color: AppThemeColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Search Field
            TextField(
              controller: _serviceSearchController,
              decoration: InputDecoration(
                hintText: 'Cari layanan atau scan barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _serviceSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _serviceSearchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            
            if (services.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Layanan tidak ditemukan',
                  style: GoogleFonts.poppins(color: AppThemeColors.textSecondary),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppThemeColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: services.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppThemeColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final isSelected = _items.any((e) => e.service.id == service.id);

                    return InkWell(
                      onTap: () => _toggleItem(service),
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(12) : Radius.zero,
                        bottom: index == services.length - 1 ? const Radius.circular(12) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                              'per ${service.unit.value}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppThemeColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Text(
                        CurrencyFormatter.format(service.price),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppThemeColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItemCard(int index, _OrderItemEntry item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Nama service dan tombol delete
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.service.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${CurrencyFormatter.format(item.service.price)}/${item.service.unit.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.discount > 0)
                        InkWell(
                          onTap: () => _showItemDiscountDialog(index, item),
                          child: Text(
                            'Diskon: -${CurrencyFormatter.format(item.discount)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppThemeColors.error,
                              height: 1.5,
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () => _showItemDiscountDialog(index, item),
                          child: Text(
                            'Tambah Diskon',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppThemeColors.primary,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeItem(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppThemeColors.error,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: Quantity controls dan subtotal
            Row(
              children: [
                // Quantity controls
                _buildQuantityControls(index, item),
                const Spacer(),
                // Subtotal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(item.subtotal),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppThemeColors.primary,
                      ),
                    ),
                    Text(
                      '${item.quantityDisplay} ${item.service.unit.value}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppThemeColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(int index, _OrderItemEntry item) {
    final isKg = item.service.unit == ServiceUnit.kg;
    final step = isKg ? 0.5 : 1.0;
    final minQuantity = isKg ? 0.5 : 1.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppThemeColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button
          InkWell(
            onTap: () {
              final newQuantity = item.quantity - step;
              if (newQuantity >= minQuantity) {
                _updateItemQuantity(index, newQuantity);
              } else {
                _removeItem(index);
              }
            },
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.remove,
                color: AppThemeColors.primary,
                size: 18,
              ),
            ),
          ),
          // Quantity display - tappable for manual input
          GestureDetector(
            onTap: () => _showQuantityInputDialog(index, item),
            child: Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppThemeColors.background,
                border: Border.symmetric(
                  vertical: BorderSide(color: AppThemeColors.border),
                ),
              ),
              child: Text(
                item.quantityDisplay,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Plus button
          InkWell(
            onTap: () => _updateItemQuantity(index, item.quantity + step),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.add,
                color: AppThemeColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    final itemDiscountTotal = _items.fold(0, (sum, item) => sum + (item.discount * item.quantity).round());
    final totalGross = _items.fold(0, (sum, item) => sum + (item.service.price * item.quantity).round());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSummaryRow('Total Nilai', totalGross),
          _buildSummaryRow(
            'Diskon Tambahan', 
            _orderDiscount,
            isClickable: true,
            onTap: _showOrderDiscountDialog,
          ),
          _buildSummaryRow(
            'Total Diskon', 
            itemDiscountTotal + _orderDiscount,
            color: AppThemeColors.error,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Bayar',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppThemeColors.textSecondary,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_netPrice),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppThemeColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Buat Order',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value, {Color? color, bool isClickable = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label, 
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isClickable ? AppThemeColors.primary : AppThemeColors.textSecondary,
                decoration: isClickable ? TextDecoration.underline : null,
              )
            ),
            Text(
              CurrencyFormatter.format(value),
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: color ?? AppThemeColors.textPrimary,
                fontWeight: color != null ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDiscountDialog(int index, _OrderItemEntry item) {
    final controller = TextEditingController(text: item.discount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Diskon ${item.service.name} (Rp)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Masukkan nilai Rupiah',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              setState(() {
                _items[index].discount = val;
                _items[index].updateSubtotal();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showOrderDiscountDialog() {
    final controller = TextEditingController(text: _orderDiscount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diskon Tambahan Pesanan (Rp)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Masukkan nilai Rupiah',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              setState(() {
                _orderDiscount = val;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _OrderItemEntry {
  final Service service;
  double quantity;
  int discount = 0;
  int subtotal;

  _OrderItemEntry({
    required this.service,
    this.quantity = 1,
  }) : subtotal = service.price;

  void updateSubtotal() {
    subtotal = ((service.price - discount) * quantity).round();
  }

  /// Format quantity display based on unit type
  String get quantityDisplay {
    if (service.unit == ServiceUnit.pcs) {
      return quantity.toInt().toString();
    } else {
      // For kg, show decimal if needed
      return quantity == quantity.roundToDouble()
          ? quantity.toInt().toString()
          : quantity.toStringAsFixed(1);
    }
  }
}

// Customer Search Bottom Sheet
class _CustomerSearchSheet extends StatefulWidget {
  final Function(Customer) onCustomerSelected;

  const _CustomerSearchSheet({required this.onCustomerSelected});

  @override
  State<_CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<_CustomerSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      context.read<CustomerCubit>().loadCustomers();
    } else {
      context.read<CustomerCubit>().searchCustomers(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppThemeColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Pilih Pelanggan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor HP...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppThemeColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                _performSearch(value);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Customer list
          Expanded(
            child: BlocBuilder<CustomerCubit, CustomerState>(
              builder: (context, state) {
                final customers = context.read<CustomerCubit>().customers;

                if (state is CustomerLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppThemeColors.primary,
                    ),
                  );
                }

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 48,
                          color: AppThemeColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Belum ada pelanggan'
                              : 'Pelanggan tidak ditemukan',
                          style: GoogleFonts.poppins(
                            color: AppThemeColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppThemeColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: AppThemeColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppThemeColors.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: customer.phone != null && customer.phone!.isNotEmpty
                          ? Text(
                              customer.phone!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppThemeColors.textSecondary,
                              ),
                            )
                          : null,
                      trailing: customer.totalOrders > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemeColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${customer.totalOrders} order',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppThemeColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : null,
                      onTap: () => widget.onCustomerSelected(customer),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
