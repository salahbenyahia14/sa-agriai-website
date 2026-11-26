# SA AgriAI Desktop for Windows

This is the first local Windows desktop prototype.

Included:
- Arabic, French, and English UI with RTL/LTR direction.
- Desktop dashboard and navigation.
- Local marketplace: create, search, and delete listings.
- Local community posts.
- Agricultural topic categories ready for sourced content.
- A trilingual source catalogue for official Algerian institutions and verified technical documents.
- Source citation and specialist-review policy in docs/SOURCE-VERIFICATION-POLICY.md.
- Supplier directory with no fabricated supplier names or ratings.
- Weather unavailable state until a trusted provider is connected.
- Dark mode and wilaya preference.
- Local persistence for preferences, listings, and posts.

Not connected:
- Firebase account system, cloud database, image uploads, push notifications, and private messaging.
- Listings and community posts remain on this PC only.
- No AI assistant or paid service is enabled.

Build on Windows:
1. Install Flutter stable and Visual Studio with Desktop development with C++.
2. Open PowerShell in this folder.
3. Run flutter config --enable-windows-desktop
4. Run flutter pub get
5. Run flutter test
6. Run flutter build windows --release

Build output is in build\windows\x64\runner\Release.
The GitHub Actions workflow builds a Windows installer. The first installer is unsigned; Windows may show a SmartScreen warning.
