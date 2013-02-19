#!/bin/sh

# Target directories without trailing slashes
input_directory='/home/tarential/voltar-ui';
output_directory='/home/tarential/voltar-ui/compiled';

# Escaped version of the input directory is used to strip it from matches.
escaped_input_directory=$(echo $input_directory | sed 's/\//\\\//g');

# Start by compiling any files which have been modified since last time the script was run.
for input_file in $(find $input_directory -not -wholename '*.git*' -not -wholename '*.sass-cache*' -name "*.*.*"); do
  input_format=$(echo $input_file | sed 's/^.*\.\([^\.]*\)$/\1/');
  output_file=`echo $input_file | sed 's/^.*\/\([^\/]*\)\.'$input_format'/\1/'`;
  output_dir=$output_directory`echo $input_file | sed 's/'$escaped_input_directory'\/\(.*\)\/'$output_file'.*/\/\1/'`;
  output_path=$output_dir'/'$output_file;

  if [ ! -d "$output_dir" ]; then
    mkdir -p $output_dir;
  fi

  compile=0
  if [ -e $output_path ]; then
    compile=1
    if [ `stat -c %Y $input_file` -gt `stat -c %Y $output_path` ]; then
      compile=0
    fi
  fi

  if [ $compile -eq 0 ]; then
    if [ $input_format = "haml" ]; then
      echo "Hamling "$input_file" to "$output_path;
      haml $input_file $output_path;
    fi

    if [ $input_format = "coffee" ]; then
      echo "Coffing "$input_file" to "$output_path;
      coffee --compile -p $input_file > $output_path;
    fi

    if [ $input_format = "scss" ]; then
      echo "Sassing "$input_file" to "$output_path;
      sass $input_file $output_path;
    fi
  fi
done

echo "AutoBuild is now watching $input_directory for changes.";

# Then monitor the directory for changes.
while inp=$(inotifywait -qre MODIFY $input_directory); do

  file_format=$(echo $inp | sed 's/^.*\.\([^\.]*\)$/\1/');
  input_file=$(echo $inp | sed 's/\s.*\s//');
  output_subdir=$(echo $inp | sed 's/'$escaped_input_directory'\(.*\)\/\s.*/\1/');
  output_file=$(echo $inp | sed 's/\(.*\)\s.*\s\(.*\)\.'$file_format'/\2/');
  output_path=$(echo $output_directory""$output_subdir"/"$output_file);

  if [ $file_format = "haml" ]; then
    echo "Hamling "$input_file" to "$output_path;
    haml $input_file $output_path;
  fi

  if [ $file_format = "coffee" ]; then
    echo "Coffing "$input_file" to "$output_path;
    coffee --compile -p $input_file > $output_path;
  fi

  if [ $file_format = "scss" ]; then
    echo "Sassing "$input_file" to "$output_path;
    sass $input_file $output_path;
  fi
done
