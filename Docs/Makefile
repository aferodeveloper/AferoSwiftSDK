PANDOC := pandoc
GITHUB_CSS := pandoc/github.css

%.html: %.md
	$(PANDOC) -f markdown_github --css $(GITHUB_CSS) --self-contained -s -o $@ $<
	
%.pdf: %.md
	$(PANDOC) -f markdown_github --css $(GITHUB_CSS) -s -o $@ $<

clean:
	rm -f *.{html,pdf}

clean-apiref:
	rm -rf Reference/*

# API
apiref:
	(cd ../Examples && \
		jazzy --author Afero \
			  --author_url http://afero.io \
			  --github_url https://github.com/aferodeveloper/AferoSwiftSDK \
			  --module_version 1.0.0 \
			  --module Afero \
			  --output ../Docs/Reference \
			  --xcodebuild-arguments \
			  -scheme,AferoLab,-workspace,AferoSwiftSDK.xcworkspace \
			  --sdk iphone\
	  )
	
