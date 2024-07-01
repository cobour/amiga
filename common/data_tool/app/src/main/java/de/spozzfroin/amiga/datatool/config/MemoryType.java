package de.spozzfroin.amiga.datatool.config;

public enum MemoryType {

	CHIP, OTHER;

	public boolean isChip() {
		return this == CHIP;
	}

	public boolean isOther() {
		return this == OTHER;
	}
}
