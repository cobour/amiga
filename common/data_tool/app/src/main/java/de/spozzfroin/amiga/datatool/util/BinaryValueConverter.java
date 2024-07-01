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
}
