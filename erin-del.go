package main

import (
    "context"
    "encoding/json"
    "flag"
    "fmt"
    "net/http"
    "os"
    "os/signal"
    "path/filepath"
    "strings"
    "syscall"
    "time"
)

// Global variables for command-line flags
var (
    allowedOrigin string // Value of the CORS origin allowed
    port          string // Port to listen on
)

func main() {
    // Parse command-line flags
    flag.StringVar(&allowedOrigin, "cors-origin", "", "Set Access-Control-Allow-Origin header")
    flag.StringVar(&port, "port", "5000", "Port to listen on")
    flag.BoolVar(&showHelp, "help", false, "Show help message and exit")
    flag.Parse()

    // Help function to show the avaliable infos 
    if showHelp {
        fmt.Println("Usage of erin-del-vid:")
        flag.PrintDefaults()
        os.Exit(0)
    }

    // Create a new ServeMux to register multiple handlers
    mux := http.NewServeMux()

    // Endpoint to delete video and JSON file
    mux.HandleFunc("/del-video", processVideo)

    // Simple health check endpoint
    mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("OK"))
    })

    // Create the HTTP server with our handler
    server := &http.Server{
        Addr:    ":" + port,
        Handler: mux,
    }

    // Log startup info
    fmt.Printf("[INFO] Server starting on :%s\n", port)
    if allowedOrigin != "" {
        fmt.Printf("[INFO] CORS enabled for origin: %s\n", allowedOrigin)
    }

    // Start the server in a goroutine so we can wait for shutdown
    go func() {
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            fmt.Fprintf(os.Stderr, "[ERROR] ListenAndServe: %v\n", err)
            os.Exit(1)
        }
    }()

    // Setup signal catching (e.g., Ctrl+C, docker stop)
    stop := make(chan os.Signal, 1)
    signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

    // Wait for a termination signal
    <-stop
    fmt.Println("\n[INFO] Shutting down server...")

    // Create context with timeout for graceful shutdown
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    // Attempt to shutdown the server gracefully
    if err := server.Shutdown(ctx); err != nil {
        fmt.Fprintf(os.Stderr, "[ERROR] Shutdown error: %v\n", err)
    } else {
        fmt.Println("[INFO] Server gracefully stopped")
    }
}

// processVideo handles POST /del-video and deletes video and .json files
func processVideo(w http.ResponseWriter, r *http.Request) {
    // Add CORS headers if enabled
    if allowedOrigin != "" {
        w.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
        w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
    }

    // Handle CORS preflight (OPTIONS request)
    if r.Method == http.MethodOptions {
        w.WriteHeader(http.StatusNoContent)
        return
    }

    // Only allow POST method for actual processing
    if r.Method != http.MethodPost {
        http.Error(w, "Invalid method", http.StatusMethodNotAllowed)
        return
    }
    
    fmt.Println("[INFO] Received POST /del-video")

    // Decode the incoming JSON request body
    var req struct {
        Filename string `json:"filename"` // expects just the file name, no path
    }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid JSON", http.StatusBadRequest)
        return
    }

    // 🚨 Security check: disallow path traversal or slashes
    if strings.Contains(req.Filename, "..") || strings.ContainsRune(req.Filename, '/') {
        http.Error(w, "Invalid filename", http.StatusBadRequest)
        return
    }

    // Construct full file paths based on sanitized filename
    videoPath := req.Filename
    jsonPath := strings.TrimSuffix(videoPath, filepath.Ext(videoPath)) + ".json"

    deleted := []string{} // list of successfully deleted files
    failed := []string{}  // list of files that couldn't be deleted

    // Try deleting the video file
    if err := os.Remove(videoPath); err == nil {
        deleted = append(deleted, req.Filename)
    } else {
        failed = append(failed, req.Filename)
        fmt.Printf("[WARN] Failed to delete video '%s': %v\n", videoPath, err)
    }

    // Try deleting the corresponding .json file
    if err := os.Remove(jsonPath); err == nil {
        deleted = append(deleted, filepath.Base(jsonPath))
    } else {
        failed = append(failed, filepath.Base(jsonPath))
        fmt.Printf("[WARN] Failed to delete JSON '%s': %v\n", jsonPath, err)
    }

     // Final summary log
    fmt.Printf("[INFO] Deletion result — Deleted: %v | Failed: %v\n", deleted, failed)

    // Prepare and send the JSON response
    response := map[string]interface{}{
        "status":  "completed",
        "deleted": deleted,
        "failed":  failed,
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(response)
}
