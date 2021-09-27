package utils

import "os"

func Exists(name string) bool {
	_, err := os.Stat(name)
	return err == nil
}

func ForceSymlink(oldname string, newname string) error {
	if Exists(newname) {
		err := os.Remove(newname)
		if err != nil {
			return err
		}
	}
	return os.Symlink(oldname, newname)
}
