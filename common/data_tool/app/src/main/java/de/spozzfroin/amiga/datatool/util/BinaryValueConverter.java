package de.spozzfroin.amiga.datatool.util;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

public class BinaryValueConverter {

	private static final BinaryValueConverter INSTANCE = new BinaryValueConverter();

	public static BinaryValueConverter getInstance() {
		return BinaryValueConverter.INSTANCE;
	}

	private BinaryValueConverter() {
		//
	}

	// BigEndian
	public int readLong(FileInputStream src) {
		try {
			byte[] bytes = new byte[4];
			src.read(bytes);
			return (bytes[0] << 24) & 0xff000000 | (bytes[1] << 16) & 0x00ff0000 | (bytes[2] << 8) & 0x0000ff00
					| (bytes[3] << 0) & 0x000000ff;
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	// BigEndian
	public int readWord(FileInputStream src) {
		try {
			byte[] bytes = new byte[2];
			src.read(bytes);
			return (bytes[0] << 8) & 0x0000ff00 | (bytes[1] << 0) & 0x000000ff;
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	public int readByte(FileInputStream src) {
		try {
			byte[] bytes = new byte[1];
			src.read(bytes);
			return bytes[0];
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	public void writeLong(String value, OutputStream data) {
		try {
			var bytes = value.getBytes();
			if (bytes.length != 4) {
				throw new RuntimeException();
			}
			data.write(bytes);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	// BigEndian
	public void writeLong(int value, OutputStream data) {
		try {
			var byteBufferX = ByteBuffer.allocate(4);
			byteBufferX.order(ByteOrder.BIG_ENDIAN);
			byteBufferX.putInt(value);
			var bytes = byteBufferX.array();
			data.write(bytes);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	// BigEndian
	public void writeWord(int value, OutputStream data) {
		try {
			var byteBufferX = ByteBuffer.allocate(4);
			byteBufferX.order(ByteOrder.BIG_ENDIAN);
			byteBufferX.putInt(value);
			var bytes = byteBufferX.array();
			data.write(bytes[2]);
			data.write(bytes[3]);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	public void writeByte(int value, OutputStream data) {
		try {
			var byteBufferX = ByteBuffer.allocate(4);
			byteBufferX.order(ByteOrder.BIG_ENDIAN);
			byteBufferX.putInt(value);
			var bytes = byteBufferX.array();
			data.write(bytes[3]);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	// LittleEndian
	public int readLongLE(FileInputStream src) {
		try {
			byte[] bytes = new byte[4];
			src.read(bytes);
			return (bytes[3] << 24) & 0xff000000 | (bytes[2] << 16) & 0x00ff0000 | (bytes[1] << 8) & 0x0000ff00
					| (bytes[0] << 0) & 0x000000ff;
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	// LittleEndian
	public int readWordLE(FileInputStream src) {
		try {
			byte[] bytes = new byte[2];
			src.read(bytes);
			return (bytes[1] << 8) & 0x0000ff00 | (bytes[0] << 0) & 0x000000ff;
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

	public long getLong(byte[] bytes, int offset) {
		long b1 = ((long) bytes[offset] << 24) & 0xff000000L;
		long b2 = ((long) bytes[offset + 1] << 16) & 0x00ff0000L;
		long b3 = ((long) bytes[offset + 2] << 8) & 0x0000ff00L;
		long b4 = ((long) bytes[offset + 3] << 0) & 0x000000ffL;
		return b1 | b2 | b3 | b4;
	}

	public void setLong(byte[] bytes, int offset, long value) {
		bytes[offset] = (byte) ((value & 0xff000000L) >> 24);
		bytes[offset + 1] = (byte) ((value & 0x00ff0000L) >> 16);
		bytes[offset + 2] = (byte) ((value & 0x0000ff00L) >> 8);
		bytes[offset + 3] = (byte) ((value & 0x000000ffL) >> 0);
	}

	public void writeFixedPointDecimal(float value, OutputStream data) {
		var negative = value < 0.0f ? true : false;
		//
		var left = (int) value;
		var rightFloat = (value - left) * 10000.0f;
		var right = (int) rightFloat;
		right = (int) (right * (65536.0f / 10000.0f));
		//
		if (negative) {
			left -= 1.0f;
			right = 65536 + right;
		}
		//
		this.writeWord(left, data);
		this.writeWord(right, data);
	}
}
