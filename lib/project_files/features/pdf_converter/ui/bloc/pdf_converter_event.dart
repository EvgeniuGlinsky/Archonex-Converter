part of 'pdf_converter_bloc.dart';

sealed class PdfConverterEvent extends Equatable {
  const PdfConverterEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The screen opened; ask whether this platform can convert at all.
final class PdfConverterStarted extends PdfConverterEvent {
  const PdfConverterStarted();
}

final class PdfSourcesPickRequested extends PdfConverterEvent {
  const PdfSourcesPickRequested();
}

final class PdfSourceRemoved extends PdfConverterEvent {
  const PdfSourceRemoved(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

final class PdfSourcesCleared extends PdfConverterEvent {
  const PdfSourcesCleared();
}

final class PdfTargetSelected extends PdfConverterEvent {
  const PdfTargetSelected(this.target);

  final PdfTarget target;

  @override
  List<Object?> get props => <Object?>[target];
}

final class PdfPageSizeChanged extends PdfConverterEvent {
  const PdfPageSizeChanged(this.pageSize);

  final PdfPageSize pageSize;

  @override
  List<Object?> get props => <Object?>[pageSize];
}

final class PdfMarginChanged extends PdfConverterEvent {
  const PdfMarginChanged(this.marginPoints);

  final double marginPoints;

  @override
  List<Object?> get props => <Object?>[marginPoints];
}

final class PdfRasterDpiChanged extends PdfConverterEvent {
  const PdfRasterDpiChanged(this.dpi);

  final int dpi;

  @override
  List<Object?> get props => <Object?>[dpi];
}

final class PdfQualityChanged extends PdfConverterEvent {
  const PdfQualityChanged(this.quality);

  final int quality;

  @override
  List<Object?> get props => <Object?>[quality];
}

final class PdfAdvancedPanelToggled extends PdfConverterEvent {
  const PdfAdvancedPanelToggled();
}

final class PdfAdvancedSettingsReset extends PdfConverterEvent {
  const PdfAdvancedSettingsReset();
}

final class PdfConversionRequested extends PdfConverterEvent {
  const PdfConversionRequested();
}

final class PdfConversionCancelled extends PdfConverterEvent {
  const PdfConversionCancelled();
}

final class ConvertedPdfSaveRequested extends PdfConverterEvent {
  const ConvertedPdfSaveRequested(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

final class AllConvertedPdfsSaveRequested extends PdfConverterEvent {
  const AllConvertedPdfsSaveRequested();
}
