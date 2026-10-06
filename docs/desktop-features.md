# Native desktop integrations

Apple-specific source is maintained in `laterbox-ios/`, including macOS companion, capture, permission, and desktop view behavior. Safari extension hosting remains in `safari_app/`.

The current Apple release scheme targets iOS. Before distributing a native macOS application, establish its build target, entitlements, signing, and release checks. Validate capture shortcuts, clipboard consent, menu-bar actions, window restoration, launch at login, local reminders, share input, and StoreKit on the actual target.

Windows and Linux native clients and system integrations are future work. Their old platform runners have been removed; browser access remains available through the web application.
