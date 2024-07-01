package de.spozzfroin.amiga.datatool.util;

public class SimpleLogger {

	private static final SimpleLogger INSTANCE = new SimpleLogger();

	public static SimpleLogger getInstance() {
		return SimpleLogger.INSTANCE;
	}

	private SimpleLogger() {
		//
	}

	public void print(String message) {
		System.out.println(message);
	}

	public void divider() {
		this.print("=======================================================================");
	}

	public void lightDivider() {
		this.print("-----------------------------------------------------------------------");
	}
}
