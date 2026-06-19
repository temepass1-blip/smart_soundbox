import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../core/database_helper.dart';
import '../core/payment_parser.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final transactions = await DatabaseHelper().getAllTransactions();
    setState(() {
      _transactions = transactions;
      _filteredTransactions = transactions;
      _isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredTransactions = _transactions.where((t) {
        return t.sender.toLowerCase().contains(_searchQuery) ||
               t.amount.toString().contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [
      ["Date", "Time", "Amount", "Sender", "Source", "UPI Ref"]
    ];

    for (var t in _transactions) {
      rows.add([
        DateFormat('dd-MMM-yyyy').format(t.timestamp),
        DateFormat('hh:mm a').format(t.timestamp),
        t.amount,
        t.sender,
        t.source,
        t.upiRef,
      ]);
    }

    String csv = rows.map((row) => row.map((e) => '"$e"').join(',')).join('\n');
    
    // In a real app, this should probably be external storage or use share_plus plugin,
    // but app documents directory works for demonstration.
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/transactions_export.csv";
    final file = File(path);
    await file.writeAsString(csv);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
    }
  }

  double get _todayTotalAmount {
    final now = DateTime.now();
    return _transactions.where((t) => t.timestamp.day == now.day && t.timestamp.month == now.month && t.timestamp.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  int get _todayTotalCount {
    final now = DateTime.now();
    return _transactions.where((t) => t.timestamp.day == now.day && t.timestamp.month == now.month && t.timestamp.year == now.year).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToCsv,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Daily Summary Card
          Card(
            margin: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Today\'s Collections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$_todayTotalCount Transactions', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  Text(
                    '₹${_todayTotalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green),
                  ),
                ],
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by sender or amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearch,
            ),
          ),
          // List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final t = _filteredTransactions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(t.source.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(t.sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy, hh:mm a').format(t.timestamp)),
                        trailing: Text(
                          '+ ₹${t.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
