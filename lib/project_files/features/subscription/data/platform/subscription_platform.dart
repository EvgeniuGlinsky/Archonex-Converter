/// Picks the subscription implementation that fits the platform.
///
/// The same boundary the converters use: which route to money exists is a
/// compile-time question on web and a runtime one everywhere else, and neither
/// answer belongs in the widget tree.
///
/// * `createSubscriptionRepo()`
library;

export 'subscription_platform_web.dart'
    if (dart.library.io) 'subscription_platform_io.dart';
