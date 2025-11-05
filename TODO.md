# TODO: Migrate from transaksi to order_list table

## Information Gathered
- Table `transaksi` is used in various places for fetch data, update `trans_status`, and create data.
- Table `order_list` has basic APIs (create, get all, get by trans_kode), but now has new backend endpoint: GET /api/order-list/kry/{kry_kode} for fetching by kry_kode.
- Service.dart already uses order_list for checking pending status.
- Affected files: api_service.dart, teknisi_home.dart, history_page.dart, history_tab.dart, tasks_tab.dart, Service.dart, riwayat.dart.

## Plan
- Add new API methods in api_service.dart: getOrderListByKryKode (using new backend endpoint), and updateOrderListStatus for update status.
- Change all fetch data from getTransaksi to getOrderList or new API methods where appropriate.
- Change update status from updateTransaksiStatus to updateOrderListStatus.
- Change create data from createTransaksi to createOrderList (already exists).
- Ensure logic remains the same, only table is changed.

## Dependent Files to be edited
- lib/api_services/api_service.dart
- lib/Teknisi/teknisi_home.dart
- lib/Teknisi/history_page.dart
- lib/Teknisi/history_tab.dart
- lib/Teknisi/tasks_tab.dart
- lib/Service/Service.dart
- lib/Others/riwayat.dart

## Tasks
- [ ] Add getOrderListByKryKode and updateOrderListStatus methods to api_service.dart
- [ ] Update teknisi_home.dart to use order_list APIs instead of transaksi
- [ ] Update history_page.dart to use order_list APIs
- [ ] Update history_tab.dart to use order_list APIs
- [ ] Update tasks_tab.dart to use order_list APIs
- [ ] Update Service.dart to use order_list APIs
- [ ] Update riwayat.dart to use order_list APIs

## Followup steps
- Test the app after changes to ensure functionality still works.
- Ensure backend APIs support operations on order_list table.
