# TODO List for Service Repair Flow Update

## Tasks
- [x] Update detail_service_midtrans.dart: Modify Ringkasan Pesanan (add Biaya Pengecekan, change Subtotal to Total Belanja, remove Voucher and Total ongkos kirim, add Biaya Teknisi above Diskon)
- [x] Update detail_service_midtrans.dart: Change navigation after payment success to TrackingPage
- [x] Create teknisi_status.dart: New page for teknisi status with dynamic display (Menunggu Teknisi Sedang Melakukan Pengecekan -> Teknisi Melakukan Service/Cleaning -> Selesai)
- [x] Update tracking_driver.dart: Change Status Service button to navigate to TeknisiStatusPage when driver arrives
- [x] Implement payment popup in teknisi_status.dart: When finished, show popup to go back to detail_service_midtrans.dart with updated prices (Biaya Teknisi filled, discount if voucher, Biaya Pengecekan crossed out)
- [x] Delete detail_service.dart as it's no longer used

## Testing
- [ ] Test Ringkasan Pesanan changes in detail_service_midtrans.dart
- [ ] Test navigation to tracking_driver.dart after payment
- [ ] Test Status Service button navigation to teknisi_status.dart
- [ ] Test dynamic status display in teknisi_status.dart
- [ ] Test payment popup and return to detail_service_midtrans.dart with updated prices
