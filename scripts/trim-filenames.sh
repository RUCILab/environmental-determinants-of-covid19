for file in *.csv; do
  newfile=`expr " $file" : ' \(.\{10\}\)'`.csv
  mv -i -f -- "$file" "$newfile"
done