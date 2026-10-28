export function traceFixture(name = 'synthetic.dat', pid = 101, {
  cpus = 1, eventsPerCpu = 3, spacing = 1_000_000,
} = {}) {
  const pageSize = 4096;
  const recordsPerPage = (pageSize - 16) / 16;
  const pagesPerCpu = Math.ceil(eventsPerCpu / recordsPerPage);
  const cpuSize = pagesPerCpu * pageSize;
  const uint16 = value => {
    const bytes = Buffer.alloc(2);
    bytes.writeUInt16LE(value);
    return bytes;
  };
  const uint32 = value => {
    const bytes = Buffer.alloc(4);
    bytes.writeUInt32LE(value);
    return bytes;
  };
  const uint64 = value => {
    const bytes = Buffer.alloc(8);
    bytes.writeBigUInt64LE(BigInt(value));
    return bytes;
  };
  const text = value => Buffer.from(value);
  const sizedText = value => Buffer.concat([uint64(Buffer.byteLength(value)), text(value)]);
  const headerPage = [
    '\tfield: u64 timestamp;\toffset:0;\tsize:8;\tsigned:0;',
    '\tfield: local_t commit;\toffset:8;\tsize:8;\tsigned:1;',
    '\tfield: int overwrite;\toffset:8;\tsize:1;\tsigned:1;',
    '\tfield: char data;\toffset:16;\tsize:4080;\tsigned:1;',
    '',
  ].join('\n');
  const eventFormat = [
    'name: tick',
    'ID: 1000',
    'format:',
    '\tfield:unsigned short common_type;\toffset:0;\tsize:2;\tsigned:0;',
    '\tfield:unsigned char common_flags;\toffset:2;\tsize:1;\tsigned:0;',
    '\tfield:unsigned char common_preempt_count;\toffset:3;\tsize:1;\tsigned:0;',
    '\tfield:int common_pid;\toffset:4;\tsize:4;\tsigned:1;',
    '',
    '\tfield:int value;\toffset:8;\tsize:4;\tsigned:1;',
    '',
    'print fmt: "value=%d", REC->value',
    '',
  ].join('\n');
  const commands = Array.from({ length: cpus }, (_unused, cpu) =>
    `${pid + cpu} test-worker\n`).join('');
  const header = Buffer.concat([
    Buffer.from([0x17, 0x08, 0x44]), text('tracing6\0'),
    Buffer.from([0, 8]), uint32(pageSize),
    text('header_page\0'), sizedText(headerPage),
    text('header_event\0'), uint64(0),
    uint32(0), uint32(1), text('test\0'), uint32(1), sizedText(eventFormat),
    uint32(0), uint32(0), sizedText(commands),
    uint32(cpus), text('options  \0'),
    uint16(4), uint32(5), text('mono\0'), uint16(0), text('flyrecord\0'),
    ...Array.from({ length: cpus }, (_unused, cpu) =>
      Buffer.concat([uint64(pageSize + cpu * cpuSize), uint64(cpuSize)])),
  ]);
  if (header.length > pageSize)
    throw new Error('Synthetic trace header exceeds one page');

  const buffer = Buffer.alloc(pageSize + cpus * cpuSize);
  header.copy(buffer);
  for (let cpu = 0; cpu < cpus; cpu++) {
    for (let pageIndex = 0; pageIndex < pagesPerCpu; pageIndex++) {
      const pageOffset = pageSize + cpu * cpuSize + pageIndex * pageSize;
      const firstIndex = pageIndex * recordsPerPage;
      const records = Math.min(recordsPerPage, eventsPerCpu - firstIndex);
      const timestamp = 1_000_000_000n + BigInt(firstIndex * spacing + cpu * 100);
      buffer.writeBigUInt64LE(timestamp, pageOffset);
      buffer.writeBigUInt64LE(BigInt(records * 16), pageOffset + 8);
      for (let index = 0; index < records; index++) {
        const offset = pageOffset + 16 + index * 16;
        buffer.writeUInt32LE((index === 0 ? 0 : spacing) * 32 + 3, offset);
        buffer.writeUInt16LE(1000, offset + 4);
        buffer.writeInt32LE(pid + cpu, offset + 8);
        buffer.writeInt32LE(firstIndex + index + 1, offset + 12);
      }
    }
  }
  return { name, mimeType: 'application/octet-stream', buffer };
}
