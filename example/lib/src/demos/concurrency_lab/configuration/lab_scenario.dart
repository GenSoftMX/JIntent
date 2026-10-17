/// Task durations used by the lab. They shrink with the id, so the concurrent
/// strategy finishes in reverse order while the sequential one keeps it.
Duration labTaskDuration(int id) => Duration(milliseconds: (6 - id) * 150);

const labTaskCount = 5;
const labTaskSpacing = Duration(milliseconds: 80);
