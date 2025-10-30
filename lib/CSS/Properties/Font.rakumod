class CSS::Properties::Font {
    use CSS::Font;
    also is is CSS::Font;
    method new(|c) is DEPRECATED<CSS::Font.new> {
        nextsame;
    }
}
