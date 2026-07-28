/// Where the licence service lives, and how much it is trusted between
/// answers.
///
/// Everything here is about an app that is offline by design asking an online
/// question. The numbers below decide how often it asks and how long it
/// believes the last answer — and every one of them errs towards letting a
/// paying user keep working, because the alternative is locking someone out of
/// software they paid for over a dropped connection.
class AppLicensePolicy {
  const AppLicensePolicy._();

  /// Root of the licence service.
  ///
  /// **This default is a placeholder and must be replaced before the first
  /// public release.** The real host is
  /// `archonex-license.SUBDOMAIN.workers.dev`, where the subdomain belongs to
  /// the Cloudflare account, so it cannot be known until that account exists. A
  /// build shipped with the placeholder still works — nothing is on sale and the
  /// paywall says so — but it can never sell anything, and it will keep pointing
  /// at the wrong host for as long as anyone has that copy.
  ///
  /// Overridable at build time, so a release can be pointed at a staging
  /// deployment without touching the source:
  ///
  /// ```
  /// flutter build windows --dart-define=ARCHONEX_LICENSE_API=https://…
  /// ```
  static const String apiBaseUrl = String.fromEnvironment(
    'ARCHONEX_LICENSE_API',
    defaultValue: 'https://archonex-license.workers.dev',
  );

  /// How long a confirmed licence is trusted before the service is asked
  /// again.
  ///
  /// A day, not an hour: the only things this catches are a cancellation, a
  /// refund and a renewal, none of which the user needs told about within
  /// minutes. Asking on every launch would spend a network round trip on the
  /// splash screen of an app whose whole pitch is working offline.
  static const Duration revalidateAfter = Duration(hours: 24);

  /// How long a licence keeps working while the service cannot be reached.
  ///
  /// Two weeks covers a holiday with no signal, a corporate firewall and an
  /// outage of the service itself. It is deliberately far longer than
  /// [revalidateAfter]: failing to *ask* is normal, and only a long silence
  /// should cost the user anything.
  static const Duration offlineGrace = Duration(days: 14);

  /// How long a single request to the service may take before it counts as no
  /// answer at all.
  static const Duration requestTimeout = Duration(seconds: 10);
}
