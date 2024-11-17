import os
import shutil
import sys

def main():
	if len(sys.argv) < 3:
		print("Usage: python rename_folder_with_assets.py <folder_path> <target_folder_name>")
		sys.exit(1)

	folder_path = sys.argv[1]
	target_folder_name = sys.argv[2]

	print(f"Folder path: {folder_path}")
	print(f"Target folder name: {target_folder_name}")

	duplicate_folder_with_assets(folder_path, target_folder_name)


def duplicate_folder_with_assets(folder_path, target_folder_name):
	folder_name = os.path.basename(os.path.normpath(folder_path))
	parent_folder = os.path.abspath(os.path.join(folder_path, os.pardir))
	target_folder_path = os.path.join(parent_folder, target_folder_name)

	if not os.path.exists(target_folder_path):
		os.makedirs(target_folder_path)

	for item in os.listdir(folder_path):
		item_path = os.path.join(folder_path, item)
		target_item_path = os.path.join(target_folder_path, item)
		if os.path.isdir(item_path):
			print(f"Copying folder: {item_path} to: {target_item_path}")
			shutil.copytree(item_path, target_item_path)
		else:
			print(f"Copying file: {item_path} to: {target_item_path}")
			shutil.copy2(item_path, target_item_path)

	for root, _, files in os.walk(target_folder_path):
		for file in files:
			file_path = os.path.join(root, file)
			replace_file_name_and_content(file_path, folder_name, target_folder_name)


def replace_file_name_and_content(file_path, folder_name, target_folder_name):
	# Handle binary files
	try:
		with open(file_path, 'r') as file:
			file_content = file.read()
	except UnicodeDecodeError:
		print(f"Skipping binary file: {file_path}")
		return

	# Replace file content using word boundaries to avoid partial matches
	import re
	pattern = r'\b' + re.escape(folder_name) + r'\b'
	new_file_content = re.sub(pattern, target_folder_name, file_content)

	# Write updated content back to original file
	with open(file_path, 'w') as file:
		file.write(new_file_content)

	# Handle file renaming
	dir_path = os.path.dirname(file_path)
	file_name = os.path.basename(file_path)

	# Only replace the exact folder name in the filename
	if folder_name in file_name:
		new_file_name = file_name.replace(folder_name, target_folder_name)
		new_file_path = os.path.join(dir_path, new_file_name)

		if new_file_path != file_path:
			print(f"Renaming: {file_path} -> {new_file_path}")
			os.rename(file_path, new_file_path)
			return new_file_path

	return file_path

if __name__ == "__main__":
	main()
