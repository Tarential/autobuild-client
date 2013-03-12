#!/bin/bash

# Target directories without trailing slashes.
input_directory='/home/tarential/voltar-ui/source';
output_directory='/home/tarential/voltar-ui/compiled';
# Manifest file path is relative to output_directory.
stylesheet_manifest_file='/stylesheets/application.css';
javascript_manifest_file='/javascripts/application.js';

# Do you need a certain load order for your js files? Specify here with relative paths:
loadjs=(
[0]=$input_directory'/javascripts/vendor/jquery-1.9.1.js'
[1]=$input_directory'/javascripts/vendor/angular-1.1.2.js'
[2]=$input_directory'/javascripts/vendor/angular-resource-1.1.2.js'
[3]=$input_directory'/javascripts/vendor/angular-sanitize-1.1.2.js'
[4]=$input_directory'/javascripts/vendor/raphael.js'
[5]=$input_directory'/javascripts/vendor/g.raphael.js'
[6]=$input_directory'/javascripts/vendor/g.bar.js'
[7]=$output_directory'/javascripts/app.js'
);

# Escaped version of the input directory is used to strip it from matches.
escaped_input_directory=$(echo $input_directory | sed 's/\//\\\//g');

# Clear the manifest files.
ss_mf=$output_directory$stylesheet_manifest_file;
js_mf=$output_directory$javascript_manifest_file;
echo '' > $ss_mf;

in_array() {
  local val;
  for val in "${@:2}"; do [[ "$val" == "$1" ]] && return 0; done
  return 1;
}

concat_scripts() {
  echo '' > $js_mf;
  concatenated_scripts=([0]=$output_directory'/javascripts/application.js');
  for input_file in "${loadjs[@]}"; do
    if !($(in_array "$input_file" "${concatenated_scripts[@]}")); then
      concatenated_scripts=(${concatenated_scripts[@]} "$input_file");
      #echo "Prioritizing addition of $input_file to js manifest.";
      cat $input_file >> $js_mf;
      echo "" >> $js_mf;
    fi
  done

  for input_file in $(find $input_directory -name "*.js"); do
    if !($(in_array "$input_file" "${concatenated_scripts[@]}")); then
      concatenated_scripts=(${concatenated_scripts[@]} $input_file);
      #echo "Adding $input_file to js manifest.";
      cat $input_file >> $js_mf;
      echo "" >> $js_mf;
    fi
  done

  for input_file in $(find $output_directory -name "*.js"); do
    if !($(in_array "$input_file" "${concatenated_scripts[@]}")); then
      concatenated_scripts=(${concatenated_scripts[@]} $input_file);
      #echo "Adding $input_file to js manifest.";
      cat $input_file >> $js_mf;
      echo "" >> $js_mf;
    fi
  done
}

# Start by compiling any files which have been modified since last time the script was run.
for input_file in $(find $input_directory -not -wholename '*.git*' -not -wholename '*.sass-cache*' -name "*.*.*"); do
  input_format=$(echo $input_file | sed 's/^.*\.\([^\.]*\)$/\1/');
  output_file=`echo $input_file | sed 's/^.*\/\([^\/]*\)\.'$input_format'/\1/'`;
  output_subpath=`echo $input_file | sed 's/'$escaped_input_directory'\/\(.*\)\/*'$output_file'.*/\/\1/'`;
  output_dir=$output_directory$output_subpath;
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

  if [ $input_format = "scss" ]; then
    #echo "Adding $output_subpath/$output_file to stylesheet development manifest.";
    echo "@import '"$output_subpath""$output_file"';" >> $output_directory"/"$stylesheet_manifest_file;
  fi
done

# Then concatenate all the scripts for easy include
concat_scripts;

# Move all the unhandled file types into the compiled directory
# Start by compiling any files which have been modified since last time the script was run.
#for input_file in $(find $input_directory -name '*.html' -o -name '*.jpg' -o -name '*.png' -o -name '*.gif' -o -name '*.ico' -o -name '*.js' ); do
for input_file in $(find $input_directory -not -wholename '*.git*' -not -wholename '*.sass-cache*' -not -name "*.haml" -not -name "*.scss" -not -name "*.coffee" -not -name "*.directory" -name "*.*"); do
  output_file=$(echo $input_file | sed 's/'$escaped_input_directory'.*\/\([^\/]*\)$/\1/')
  output_subdir=$(echo $input_file | sed 's/'$escaped_input_directory'\(.*\)\/[^\/]*$/\1/')
  output_dir=$output_directory$output_subdir
  output_path=$output_dir'/'$output_file

  if [ ! -d "$output_dir" ]; then
    mkdir -p $output_dir;
  fi

  link_file=0
  if [ -e $output_path ]; then
    link_file=1
    if [ `stat -c %Y $input_file` -gt `stat -c %Y $output_path` ]; then
      link_file=0
    fi
  fi

  if [ $link_file -eq 0 ]; then
    echo "Linking $input_file to $output_path"
    ln -s $input_file $output_path
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
    concat_scripts;
  fi

  if [ $file_format = "scss" ]; then
    echo "Sassing "$input_file" to "$output_path;
    sass $input_file $output_path;
  fi
done
