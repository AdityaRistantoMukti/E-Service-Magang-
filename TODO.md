# TODO: Integrate Promo in Checkout Page

- [x] Add promo fetching in initState
- [x] Create _isProductInPromo method to check if product is in promo
- [x] Conditionally show "Gunakan Poin" toggle only for promo products

# TODO: Make detail_service_midtrans.dart Responsive

- [ ] Add LayoutBuilder and MediaQuery for screen size detection
- [ ] Scale paddings proportionally (e.g., EdgeInsets.all(12) -> EdgeInsets.all(12 * scale))
- [ ] Scale icon sizes (e.g., size: 40 -> size: 40 * scale)
- [ ] Scale text sizes (e.g., fontSize: 16 -> fontSize: 16 * scale)
- [ ] Adjust dialog sizes to fit smaller screens
- [ ] Test on different screen sizes (small, medium, large)
