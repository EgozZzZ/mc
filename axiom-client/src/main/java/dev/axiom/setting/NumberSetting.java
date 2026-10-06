package dev.axiom.setting;
public class NumberSetting extends Setting<Double> {
    public final double min, max;
    public NumberSetting(String name, double defaultValue, double min, double max) {
        super(name, defaultValue); this.min = min; this.max = max;
    }
    @Override public void setValue(Double value) {
        this.value = Math.max(min, Math.min(max, value));
    }
}
