export function traceFixture(name = 'synthetic.dat', pid = 101) {
  const pageSize = 4096;
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
  const commands = `${pid} test-worker\n`;
  const header = Buffer.concat([
    Buffer.from([0x17, 0x08, 0x44]), text('tracing6\0'),
    Buffer.from([0, 8]), uint32(pageSize),
    text('header_page\0'), sizedText(headerPage),
    text('header_event\0'), uint64(0),
    uint32(0), uint32(1), text('test\0'), uint32(1), sizedText(eventFormat),
    uint32(0), uint32(0), sizedText(commands),
    uint32(1), text('flyrecord\0'), uint64(pageSize), uint64(pageSize),
  ]);
  if (header.length > pageSize)
    throw new Error('Synthetic trace header exceeds one page');

  const buffer = Buffer.alloc(pageSize * 2);
  header.copy(buffer);
  buffer.writeBigUInt64LE(1_000_000_000n, pageSize);
  buffer.writeBigUInt64LE(48n, pageSize + 8);
  for (let index = 0; index < 3; index++) {
    const offset = pageSize + 16 + index * 16;
    buffer.writeUInt32LE((index === 0 ? 0 : 1_000_000) * 32 + 3, offset);
    buffer.writeUInt16LE(1000, offset + 4);
    buffer.writeInt32LE(pid, offset + 8);
    buffer.writeInt32LE(index + 1, offset + 12);
  }
  return { name, mimeType: 'application/octet-stream', buffer };
}
