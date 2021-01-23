for filename in *.fnl; do
    fennel --compile "$filename" > "${filename%.*}".lua
done

love .

for filename in *.fnl; do
    rm "${filename%.*}".lua
done