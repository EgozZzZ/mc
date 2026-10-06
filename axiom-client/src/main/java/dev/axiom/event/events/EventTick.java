package dev.axiom.event.events;
public class EventTick {
    public enum Stage { PRE, POST }
    public final Stage stage;
    public EventTick(Stage stage) { this.stage = stage; }
}
