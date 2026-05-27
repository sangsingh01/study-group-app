Google Sign-In (Web) setup
--------------------------------

To avoid runtime errors from package:google_sign_in on web, add your OAuth Web Client ID to `web/index.html`:

1. Open the Google Cloud Console and create an OAuth 2.0 Client ID (Web application).
2. Copy the Client ID and replace `CLIENT_ID` in `web/index.html` meta tag:

   <meta name="google-signin-client_id" content="YOUR_CLIENT_ID">

3. Rebuild the app for web.

If you prefer not to enable GoogleSignIn on web, keep the placeholder meta tag and the app will fall back to Firebase `signInWithPopup`.
