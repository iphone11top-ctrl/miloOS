.PHONY: image check smoke clean

image:
	./tools/build-image.sh

check: image
	./tools/check-image.sh

smoke: image
	./tools/smoke-test.sh

clean:
	rm -rf build
