// modal_provider_test.dart
//
// Unit tests for ModalProvider.

import "package:flutter/widgets.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("show mounts the modal and dismiss removes it", () {
    final ModalProvider provider = ModalProvider();
    int notifications = 0;
    provider.addListener(() => notifications++);

    const Widget modal = SizedBox.shrink();
    provider.show(modal);
    expect(provider.currentModal, same(modal));

    provider.dismiss();
    expect(provider.currentModal, isNull);
    expect(notifications, 2);
  });

  test("dismiss without a modal does not notify", () {
    final ModalProvider provider = ModalProvider();
    int notifications = 0;
    provider.addListener(() => notifications++);

    provider.dismiss();
    expect(notifications, 0);
  });
}
