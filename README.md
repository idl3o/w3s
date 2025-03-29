Web3 Crypto Streaming Service
============================

A blockchain-based streaming service with cryptocurrency payment integration.

Features:
- Stripe payment processing integration
- Token-based access system 
- Secure payment handling
- Currency conversion support

Setup:
1. Install dependencies:
   npm install stripe

2. Configure Stripe:
   - Replace 'your-stripe-secret-key' in paymentService.js with your actual Stripe secret key
   - Ensure you have a Stripe account and API access

3. Environment Setup:
   - Node.js 14+ recommended
   - Secure environment for API keys
   - HTTPS enabled for production

Usage:
The payment service provides two main functions:
- processPayment: Handle direct payments via Stripe
- increaseTokens: Purchase and add tokens to user accounts

For detailed API documentation, please refer to the code comments in paymentService.js.

Security Note:
Never commit API keys or sensitive credentials to version control.
Always use environment variables for production deployments.
