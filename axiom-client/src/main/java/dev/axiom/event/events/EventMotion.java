package dev.axiom.event.events;
public class EventMotion {
    public float yaw, pitch;
    public boolean cancelled;
    public EventMotion(float yaw, float pitch) { this.yaw = yaw; this.pitch = pitch; }
}
