#define _FILE_OFFSET_BITS 64

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

static void usage(const char *program)
{
	fprintf(stderr, "Usage: %s ADDRESS [WIDTH [VALUE]]\n", program);
	fprintf(stderr, "WIDTH is 8, 16, 32, or 64 bits (default: 32).\n");
}

static int parse_u64(const char *text, uint64_t *value)
{
	char *end;
	unsigned long long parsed;

	errno = 0;
	parsed = strtoull(text, &end, 0);
	if (errno != 0 || *text == '\0' || *end != '\0')
		return -1;

	*value = parsed;
	return 0;
}

static int parse_width(const char *text, unsigned int *width)
{
	if (strcmp(text, "8") == 0 || strcmp(text, "b") == 0) {
		*width = 8;
	} else if (strcmp(text, "16") == 0 || strcmp(text, "h") == 0) {
		*width = 16;
	} else if (strcmp(text, "32") == 0 || strcmp(text, "w") == 0) {
		*width = 32;
	} else if (strcmp(text, "64") == 0 || strcmp(text, "l") == 0) {
		*width = 64;
	} else {
		return -1;
	}

	return 0;
}

int main(int argc, char **argv)
{
	uint64_t address;
	uint64_t value = 0;
	unsigned int width = 32;
	long page_size;
	off_t page_base;
	off_t page_offset;
	void *mapping;
	volatile void *register_address;
	int mem_fd;

	if (argc < 2 || argc > 4 || parse_u64(argv[1], &address) != 0 ||
	    (argc >= 3 && parse_width(argv[2], &width) != 0) ||
	    (argc == 4 && parse_u64(argv[3], &value) != 0)) {
		usage(argv[0]);
		return EXIT_FAILURE;
	}

	if (address > INT64_MAX || address % (width / 8) != 0) {
		fprintf(stderr, "%s: invalid address 0x%" PRIx64 " for %u-bit access\n",
			argv[0], address, width);
		return EXIT_FAILURE;
	}

	page_size = sysconf(_SC_PAGESIZE);
	if (page_size <= 0) {
		perror("sysconf(_SC_PAGESIZE)");
		return EXIT_FAILURE;
	}

	page_base = (off_t)(address & ~((uint64_t)page_size - 1));
	page_offset = (off_t)(address - (uint64_t)page_base);
	mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
	if (mem_fd < 0) {
		perror("/dev/mem");
		return EXIT_FAILURE;
	}

	mapping = mmap(NULL, (size_t)page_size, PROT_READ | PROT_WRITE, MAP_SHARED,
		       mem_fd, page_base);
	if (mapping == MAP_FAILED) {
		perror("mmap(/dev/mem)");
		close(mem_fd);
		return EXIT_FAILURE;
	}

	register_address = (volatile char *)mapping + page_offset;
	if (argc == 4) {
		switch (width) {
		case 8:
			*(volatile uint8_t *)register_address = (uint8_t)value;
			break;
		case 16:
			*(volatile uint16_t *)register_address = (uint16_t)value;
			break;
		case 32:
			*(volatile uint32_t *)register_address = (uint32_t)value;
			break;
		default:
			*(volatile uint64_t *)register_address = value;
			break;
		}
	} else {
		switch (width) {
		case 8:
			value = *(volatile uint8_t *)register_address;
			break;
		case 16:
			value = *(volatile uint16_t *)register_address;
			break;
		case 32:
			value = *(volatile uint32_t *)register_address;
			break;
		default:
			value = *(volatile uint64_t *)register_address;
			break;
		}
		printf("0x%" PRIx64 "\n", value);
	}

	munmap(mapping, (size_t)page_size);
	close(mem_fd);
	return EXIT_SUCCESS;
}
