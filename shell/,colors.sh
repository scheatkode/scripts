#/bin/sh

# Print the console's 255 colors.

for i in $(seq 0 255) ; do
   printf "\x1b[48;5;%sm %3d \e[0m " "${i}" "${i}"

   if [ $(( (i - 15) % 36)) -eq 0 ] ; then
      printf "\n"
   fi

   if [ ${i} -eq 7 ] || [ ${i} -eq 15 ] ; then
      printf "\n";
      continue
   fi

   if [ "${i}" -gt 15 ] && [ $(( (i - 15) % 6 )) -eq 0 ] ; then
      printf "\n";
   fi
done
