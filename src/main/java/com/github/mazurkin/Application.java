package com.github.mazurkin;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class Application {

    private static final Logger LOGGER = LoggerFactory.getLogger(Application.class);

    private final String message;

    public Application() {
        this.message = "Hello World!";
    }

    public void run() {
        LOGGER.info(this.message);
    }

    public static void main(String[] arguments) {
        Application application = new Application();
        application.run();
    }
}
