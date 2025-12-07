package main

import (
    "encoding/json"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        json.NewEncoder(w).Encode(map[string]string{
            "message": "{{PROJECT}}",
            "org": "{{ORG}}",
            "env": "{{ENV}}",
        })
    })
    
    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
    })
    
    log.Fatal(http.ListenAndServe(":8080", nil))
}
