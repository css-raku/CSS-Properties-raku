DocProj=css-raku.github.io
DocRepo=https://github.com/css-raku/$(DocProj)
DocLinker=../$(DocProj)/etc/resolve-links.raku

all : doc

test : all
	@prove -e"raku -I ." t

loudtest : all
	@prove -e"raku -I ." -v t

$(DocLinker) :
	(cd .. && git clone $(DocRepo) $(DocProj))

doc : $(DocLinker) docs/index.md docs/CSS/Properties.md docs/CSS/Properties/Calculator.md docs/CSS/Properties/Property.md docs/CSS/Box.md docs/CSS/PageBox.md docs/CSS/Units.md docs/CSS/Font.md

docs/index.md : README.md
	cp $< $@

docs/%.md : lib/%.rakumod
	raku -I . --doc=Markdown $< \
	| TRAIL=$* raku -p -n $(DocLinker) \
	> $@
