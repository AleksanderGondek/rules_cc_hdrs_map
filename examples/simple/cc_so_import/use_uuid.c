#include "use_uuid.h"

void print_uuid() {
  uuid_t uuid;
  uuid_generate_time_safe(uuid);
  char uuid_str[37];
  uuid_unparse_lower(uuid, uuid_str);
  printf("%s\n", uuid_str);
}
