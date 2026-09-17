final class _Omitted implements DateTime {
  const _Omitted();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const DateTime omitted = _Omitted();

bool isOmitted(DateTime? value) => identical(value, omitted);
