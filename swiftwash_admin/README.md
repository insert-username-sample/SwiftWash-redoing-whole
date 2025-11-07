# SwiftWash Admin

A comprehensive administrative dashboard for SwiftWash platform management, designed exclusively for founders (Manas and Kashinath).

## 🔐 Security Features

### Authentication
- **Founder-Only Access**: Only two predefined users can access the admin panel
  - `manas-founder` with password `FoundersOffice`
  - `kashinath-founder` with password `FoundersOffice`
- **No Registration**: No user registration system - founders only
- **Session Management**: Automatic logout after configurable timeout

### Data Protection
- **Environment Variables**: Sensitive configuration stored in encrypted environment files
- **Input Validation**: Comprehensive validation for all user inputs
- **Data Sanitization**: Automatic sanitization of user inputs to prevent injection attacks
- **Encryption**: AES-256 encryption for sensitive data storage
- **Rate Limiting**: API rate limiting to prevent abuse

### Network Security
- **HTTPS Only**: All API communications use secure HTTPS
- **Security Headers**: Comprehensive security headers implementation
- **CSRF Protection**: Cross-Site Request Forgery protection
- **Request Validation**: All API requests validated and sanitized

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ^3.9.0
- Dart SDK compatible with Flutter
- Access to Firebase project (for data access)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd swiftwash_admin
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**

   Copy the environment template:
   ```bash
   cp .env.prod.template .env.prod
   ```

   Edit `.env.prod` with your production values:
   ```env
   # Firebase Configuration
   FIREBASE_PROJECT_ID=your_production_firebase_project_id
   FIREBASE_API_KEY=your_production_firebase_api_key
   # ... other production values

   # Security (Generate strong keys)
   ENCRYPTION_KEY=your_32_character_encryption_key_here
   JWT_SECRET=your_secure_jwt_secret_here
   ```

4. **Firebase Setup**
   - Ensure Firebase project has Firestore enabled
   - Configure Firestore security rules for admin access
   - Set up Firebase Authentication (if needed for data access)

### Running the Application

#### Development
```bash
flutter run --debug
```

#### Production Build
```bash
flutter build apk --release
flutter build ios --release
```

## 📊 Features

### Dashboard
- **Real-time Analytics**: Live business metrics and KPIs
- **Revenue Tracking**: Daily, monthly, and service-wise revenue
- **Order Management**: Recent orders with status tracking
- **Driver Performance**: Online status, ratings, and completion rates

### Management Interfaces
- **User Management**: View, edit, and manage user accounts
- **Driver Oversight**: Approve drivers, manage assignments, track performance
- **Order Control**: Update order status, cancel orders, assign drivers
- **System Settings**: Configure pricing, system parameters

### Security Dashboard
- **Access Logs**: Monitor admin access and activities
- **Rate Limit Status**: View API usage and limits
- **Security Alerts**: Real-time security monitoring

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `FIREBASE_PROJECT_ID` | Firebase project ID | Yes | - |
| `ENCRYPTION_KEY` | 32-char encryption key | Yes | - |
| `SESSION_TIMEOUT_MINUTES` | Admin session timeout | No | 30 |
| `MAX_REQUESTS_PER_MINUTE` | API rate limit | No | 60 |
| `ENABLE_ANALYTICS` | Enable analytics | No | false |

### Security Settings

- **Encryption Key**: Must be exactly 32 characters for AES-256
- **Session Timeout**: Automatically logs out inactive admins
- **Rate Limiting**: Prevents API abuse and ensures fair usage
- **Input Validation**: All inputs validated before processing

## 🛡️ Security Best Practices

### For Production Deployment

1. **Environment Variables**
   - Never commit `.env.prod` to version control
   - Use strong, unique encryption keys
   - Rotate keys regularly

2. **Firebase Security**
   - Implement strict Firestore security rules
   - Use Firebase Authentication for data access
   - Enable Firebase Security features

3. **Network Security**
   - Use HTTPS for all communications
   - Implement certificate pinning
   - Regular security audits

4. **Data Protection**
   - Encrypt sensitive data at rest
   - Implement proper data retention policies
   - Regular data backups

### Monitoring

- **Access Logs**: Monitor admin login/logout activities
- **API Usage**: Track API calls and rate limit violations
- **Error Monitoring**: Log and alert on security-related errors
- **Performance Monitoring**: Monitor app performance and security metrics

## 🐛 Troubleshooting

### Common Issues

1. **Environment Configuration**
   ```
   Error: Missing required environment variables
   ```
   - Ensure `.env.prod` exists with all required variables
   - Check variable names match exactly

2. **Encryption Key Issues**
   ```
   Encryption key must be at least 16 characters long
   ```
   - Generate a 32-character encryption key
   - Use secure random generation

3. **Firebase Connection**
   ```
   Firebase project not configured
   ```
   - Verify Firebase project ID in environment
   - Check Firebase configuration

### Debug Mode

Enable debug logging in development:
```env
ENABLE_DEBUG_LOGGING=true
```

## 📝 API Documentation

### Authentication Endpoints
- `POST /auth/login` - Admin login
- `POST /auth/logout` - Admin logout
- `GET /auth/verify` - Verify session

### Management Endpoints
- `GET /users` - List users
- `GET /drivers` - List drivers
- `GET /orders` - List orders
- `POST /orders/{id}/status` - Update order status

### Security Headers

All API requests include:
- `X-API-Key`: Encrypted API key
- `X-Timestamp`: Request timestamp
- `X-CSRF-Token`: CSRF protection token
- `X-Client-Version`: App version

## 🤝 Contributing

### Security Guidelines
- Never commit sensitive data or keys
- Use environment variables for configuration
- Implement input validation for all user inputs
- Follow secure coding practices
- Regular security code reviews

### Code Standards
- Use strong typing
- Implement proper error handling
- Add comprehensive logging
- Write unit tests for security functions

## 📞 Support

For security-related issues or questions:
- Contact founders directly
- Check security logs in admin dashboard
- Review Firebase security rules

## 📋 Changelog

### Version 1.0.0
- Initial release with founder-only authentication
- Complete admin dashboard with real-time analytics
- Comprehensive security hardening
- Production-ready architecture

---

**⚠️ Security Notice**: This application contains sensitive administrative functions. Access is restricted to authorized founders only. All security measures are implemented to protect SwiftWash platform data and operations.
