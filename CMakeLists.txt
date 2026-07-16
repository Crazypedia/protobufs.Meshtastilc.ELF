cmake_minimum_required(VERSION 3.20)

# Embedded protobuf codec: nanopb runtime + generated .pb.c sources.
# Regenerate the sources with ./generate-nanopb.sh after changing
# .proto or .options files.
#
# Consumed by Tactility as a dual-target component: an ESP-IDF component
# when built under idf.py, a plain static library otherwise.

set(NANOPB_RUNTIME_SOURCES
    nanopb/pb_common.c
    nanopb/pb_decode.c
    nanopb/pb_encode.c
)

# *.pb.cpp: deviceonly uses std::vector callback datatypes (upstream choice),
# so it is generated as a C++ source; its header is C++-only as well.
file(GLOB GENERATED_SOURCES generated/meshtastic/*.pb.c generated/meshtastic/*.pb.cpp)

if (DEFINED ENV{ESP_IDF_VERSION})
    idf_component_register(
        SRCS ${NANOPB_RUNTIME_SOURCES} ${GENERATED_SOURCES}
        INCLUDE_DIRS "nanopb" "generated"
    )
else()
    add_library(meshtastic_pb STATIC)
    target_sources(meshtastic_pb PRIVATE ${NANOPB_RUNTIME_SOURCES} ${GENERATED_SOURCES})
    target_include_directories(meshtastic_pb PUBLIC nanopb generated)
endif()
