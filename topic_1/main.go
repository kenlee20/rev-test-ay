package main

import (
	"fmt"
	"log"
	"os"
	"unicode"
)

func statistics(file string) string {
	f, err := os.ReadFile(file)
	if err != nil {
		log.Fatal(err)
	}

	word := []rune{}
	isWord := false
	total := make(map[string]int, 0)

	for _, rune_w := range string(f) {
		// check if the rune is a letter or a number, then add it to the word
		if !unicode.IsLetter(rune_w) && !unicode.IsNumber(rune_w) {
			if isWord {
				total[string(word)]++
				word = []rune{}
				isWord = false
			}
			continue
		}
		// check if the rune is a upper case letter
		if unicode.IsUpper(rune_w) {
			rune_w = unicode.ToLower(rune_w)
		}
		word = append(word, rune_w)
		isWord = true
	}

	var (
		maxWord  string
		maxCount int
	)
	// find the word with the highest count
	for key, count := range total {
		if count > maxCount {
			maxWord = key
			maxCount = count
		}
	}
	return fmt.Sprintf("%d %s", maxCount, maxWord)
}

func main() {
	word := statistics("./words.txt")
	fmt.Println(word)
}
