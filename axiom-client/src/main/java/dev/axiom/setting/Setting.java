package dev.axiom.setting;
public abstract class Setting<T> {
    public final String name;
    protected T value;
    public Setting(String name, T defaultValue) { this.name = name; this.value = defaultValue; }
    public T getValue() { return value; }
    public void setValue(T value) { this.value = value; }
}
