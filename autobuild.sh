#!/bin/sh

# Target directories without trailing slashes
input_directory='/home/tarential/voltar-ui';
output_directory='/home/tarential/voltar-ui/compiled';

while inp=$(inotifywait -r -e MODIFY $input_directory); do

  file_format=$(echo $inp | sed 's/^.*\.\([^\.]*\)$/\1/');
  input_file=$(echo $inp | sed 's/\s.*\s//');
  escaped_input_directory=$(echo $input_directory | sed 's/\//\\\//g');
  output_subdir=$(echo $inp | sed 's/'$escaped_input_directory'\(.*\)\/\s.*/\1/');
  output_file=$(echo $inp | sed 's/\(.*\)\s.*\s\(.*\)\.'$file_format'/\2/');
  output_path=$(echo $output_directory""$output_subdir"/"$output_file);

  echo "Escaped Input Dir: "$escaped_input_directory;
  echo "File Format: "$file_format;
  echo "Input File: "$input_file;
  echo "Output Subdir: "$output_subdir;
  echo "Output File: "$output_file;
  echo "Output Path: "$output_path;

  if [ $file_format = "haml" ]; then
    echo "Hamling "$input_file" to "$output_path;
    #haml $input_file $output_file;
  fi

  if [ $file_format = "coffee" ]; then
    echo "Coffeeing "$input_file" to "$output_path;
    #coffee --compile -p $input_file > $output_file;
  fi

  if [ $file_format = "scss" ]; then
    echo "SCSSing "$input_file" to "$output_path;
    #sass $input_file $output_file;
  fi
done
