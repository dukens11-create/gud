import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/load.dart';
import '../services/invoice_service.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const CreateInvoiceScreen({super.key, this.invoice});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceService = InvoiceService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Form controllers
  String? _selectedLoadId;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  // Company info
  final _companyNameController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyCityController = TextEditingController();
  final _companyStateController = TextEditingController();
  final _companyZipController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();

  // Client info
  final _clientNameController = TextEditingController();
  final _clientAddressController = TextEditingController();
  final _clientCityController = TextEditingController();
  final _clientStateController = TextEditingController();
  final _clientZipController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientEmailController = TextEditingController();

  // Line items
  List<LineItemData> _lineItems = [LineItemData()];

  // Tax and notes
  final _taxRateController = TextEditingController(text: '0.0');
  final _notesController = TextEditingController();

  bool _isLoading = false;
  List<LoadModel> _availableLoads = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableLoads();

    if (widget.invoice != null) {
      _populateFromInvoice(widget.invoice!);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyAddressController.dispose();
    _companyCityController.dispose();
    _companyStateController.dispose();
    _companyZipController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _clientNameController.dispose();
    _clientAddressController.dispose();
    _clientCityController.dispose();
    _clientStateController.dispose();
    _clientZipController.dispose();
    _clientPhoneController.dispose();
    _clientEmailController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromInvoice(Invoice invoice) {
    _selectedLoadId = invoice.loadId;
    _issueDate = invoice.issueDate;
    _dueDate = invoice.dueDate;

    _companyNameController.text = invoice.companyInfo.name;
    _companyAddressController.text = invoice.companyInfo.address;
    _companyCityController.text = invoice.companyInfo.city;
    _companyStateController.text = invoice.companyInfo.state;
    _companyZipController.text = invoice.companyInfo.zip;
    _companyPhoneController.text = invoice.companyInfo.phone ?? '';
    _companyEmailController.text = invoice.companyInfo.email ?? '';

    _clientNameController.text = invoice.clientInfo.name;
    _clientAddressController.text = invoice.clientInfo.address;
    _clientCityController.text = invoice.clientInfo.city;
    _clientStateController.text = invoice.clientInfo.state;
    _clientZipController.text = invoice.clientInfo.zip;
    _clientPhoneController.text = invoice.clientInfo.phone ?? '';
    _clientEmailController.text = invoice.clientInfo.email ?? '';

    _lineItems = invoice.lineItems
        .map((item) => LineItemData(
              descriptionController: TextEditingController(text: item.description),
              quantityController: TextEditingController(text: item.quantity.toString()),
              unitPriceController: TextEditingController(text: item.unitPrice.toString()),
            ))
        .toList();

    final taxRate = invoice.subtotal > 0 ? (invoice.tax / invoice.subtotal) * 100 : 0.0;
    _taxRateController.text = taxRate.toStringAsFixed(2);
    _notesController.text = invoice.notes ?? '';
  }

  Future<void> _loadAvailableLoads() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('loads')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      setState(() {
        _availableLoads = snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();
      });
    } catch (e) {
      debugPrint('Error loading loads: $e');
    }
  }

  double get _subtotal {
    return _lineItems.fold(0.0, (sum, item) {
      final quantity = double.tryParse(item.quantityController.text) ?? 0.0;
      final unitPrice = double.tryParse(item.unitPriceController.text) ?? 0.0;
      return sum + (quantity * unitPrice);
    });
  }

  double get _tax {
    final taxRate = double.tryParse(_taxRateController.text) ?? 0.0;
    return _subtotal * (taxRate / 100);
  }

  double get _total {
    return _subtotal + _tax;
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(LineItemData());
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length > 1) {
      setState(() {
        _lineItems[index].dispose();
        _lineItems.removeAt(index);
      });
    }
  }

  Future<void> _saveInvoice({bool sendImmediately = false}) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one line item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final companyInfo = CompanyInfo(
        name: _companyNameController.text.trim(),
        address: _companyAddressController.text.trim(),
        city: _companyCityController.text.trim(),
        state: _companyStateController.text.trim(),
        zip: _companyZipController.text.trim(),
        phone: _companyPhoneController.text.trim().isNotEmpty
            ? _companyPhoneController.text.trim()
            : null,
        email: _companyEmailController.text.trim().isNotEmpty
            ? _companyEmailController.text.trim()
            : null,
      );

      final clientInfo = CompanyInfo(
        name: _clientNameController.text.trim(),
        address: _clientAddressController.text.trim(),
        city: _clientCityController.text.trim(),
        state: _clientStateController.text.trim(),
        zip: _clientZipController.text.trim(),
        phone: _clientPhoneController.text.trim().isNotEmpty
            ? _clientPhoneController.text.trim()
            : null,
        email: _clientEmailController.text.trim().isNotEmpty
            ? _clientEmailController.text.trim()
            : null,
      );

      final lineItems = _lineItems.map((item) {
        final quantity = double.parse(item.quantityController.text);
        final unitPrice = double.parse(item.unitPriceController.text);
        return InvoiceLineItem(
          description: item.descriptionController.text.trim(),
          quantity: quantity,
          unitPrice: unitPrice,
          amount: quantity * unitPrice,
        );
      }).toList();

      final invoice = Invoice(
        id: widget.invoice?.id,
        loadId: _selectedLoadId,
        invoiceNumber: widget.invoice?.invoiceNumber ?? '',
        issueDate: _issueDate,
        dueDate: _dueDate,
        companyInfo: companyInfo,
        clientInfo: clientInfo,
        lineItems: lineItems,
        subtotal: _subtotal,
        tax: _tax,
        total: _total,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        status: sendImmediately ? InvoiceStatus.sent : InvoiceStatus.draft,
      );

      if (widget.invoice?.id != null) {
        // Update existing invoice
        await _invoiceService.updateInvoice(widget.invoice!.id!, invoice);
      } else {
        // Create new invoice
        await _invoiceService.createInvoice(invoice);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.invoice != null
                ? 'Invoice updated successfully'
                : 'Invoice created successfully'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice != null ? 'Edit Invoice' : 'Create Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Load selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Load (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLoadId,
                      decoration: const InputDecoration(
                        labelText: 'Select Load',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._availableLoads.map((load) => DropdownMenuItem(
                              value: load.id,
                              child: Text('${load.loadNumber} - ${load.pickupAddress}'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedLoadId = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Dates',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Issue Date'),
                      subtitle: Text(_dateFormat.format(_issueDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _issueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _issueDate = date);
                        }
                      },
                    ),
                    ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(_dateFormat.format(_dueDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _dueDate = date);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Company info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Company Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _companyCityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _companyStateController,
                            decoration: const InputDecoration(
                              labelText: 'State *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _companyZipController,
                            decoration: const InputDecoration(
                              labelText: 'ZIP *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Client info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Client Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _clientAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Address *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _clientCityController,
                            decoration: const InputDecoration(
                              labelText: 'City *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _clientStateController,
                            decoration: const InputDecoration(
                              labelText: 'State *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _clientZipController,
                            decoration: const InputDecoration(
                              labelText: 'ZIP *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _clientPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _clientEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Line items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Line Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addLineItem,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._lineItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildLineItemRow(index, item);
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tax and totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tax & Totals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _taxRateController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Rate (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildTotalRow('Subtotal:', _subtotal),
                    _buildTotalRow('Tax:', _tax),
                    const Divider(thickness: 2),
                    _buildTotalRow('TOTAL:', _total, isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Additional notes or terms',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => _saveInvoice(sendImmediately: false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Save as Draft'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _saveInvoice(sendImmediately: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Save and Send'),
                  ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemRow(int index, LineItemData item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: item.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Qty *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: item.unitPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Price *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(value!) == null) return 'Invalid';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_lineItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeLineItem(index),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Amount: \$${_calculateLineItemAmount(item).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateLineItemAmount(LineItemData item) {
    final quantity = double.tryParse(item.quantityController.text) ?? 0.0;
    final unitPrice = double.tryParse(item.unitPriceController.text) ?? 0.0;
    return quantity * unitPrice;
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class LineItemData {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  LineItemData({
    TextEditingController? descriptionController,
    TextEditingController? quantityController,
    TextEditingController? unitPriceController,
  })  : descriptionController = descriptionController ?? TextEditingController(),
        quantityController = quantityController ?? TextEditingController(text: '1'),
        unitPriceController = unitPriceController ?? TextEditingController(text: '0.00');

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
