package de.spozzfroin.amiga.datatool.config.sources;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

public enum SourceType {

	ASSEMBLER("ASM "), IFF("IFF "), MOD("MOD "), WAV("WAV "), TILED_PLAYFIELD("TLDP"), PALETTE("COLS");

	// see datafiles.i
	private final String type;

	private SourceType(String theType) {
		this.type = theType;
	}

	public int asInt() {
		var bb = ByteBuffer.wrap(this.type.getBytes(StandardCharsets.US_ASCII));
		return bb.getInt();
	}

	@Override
	public String toString() {
		return this.type;
	}
}
