import os
import requests
import time
from urllib.parse import urlparse, urljoin, quote
import hashlib
from pathlib import Path
import json
import re
from bs4 import BeautifulSoup
import random

class ImageDatasetCreator:
    def __init__(self, base_dir="dataset"):
        """
        Initialize the dataset creator
        
        Args:
            base_dir (str): Base directory to store the dataset
        """
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(exist_ok=True)
        
        # User agents to rotate for avoiding blocks
        self.user_agents = [
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15',
            'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        ]
        
        # Object categories and items
        self.objects = {
            "kitchen": ["cup mug", "plate", "spoon", "water bottle", "apple"],
            "living_room": ["chair", "table", "book", "soccer ball football", "bag backpack"],
            "personal": ["shoes", "toothbrush", "towel", "comb", "pencil pen"],
            "learning_educational": ["television", "key", "clock", "notebook", "radio"]
        }
    
    def get_random_headers(self):
        """Get random headers to avoid blocking"""
        return {
            'User-Agent': random.choice(self.user_agents),
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
    
    def search_duckduckgo_images(self, query, max_images=100):
        """
        Search for images using DuckDuckGo (no API key needed)
        
        Args:
            query (str): Search query
            max_images (int): Maximum number of image URLs to return
            
        Returns:
            list: List of image URLs
        """
        image_urls = []
        
        try:
            # DuckDuckGo image search URL
            search_url = f"https://duckduckgo.com/?q={quote(query)}&t=h_&iax=images&ia=images"
            
            headers = self.get_random_headers()
            
            # First, get the search page
            response = requests.get(search_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            # DuckDuckGo loads images via JavaScript, so we need to make a request to their API
            # Get the vqd token needed for the API
            soup = BeautifulSoup(response.text, 'html.parser')
            vqd_match = re.search(r'vqd=([\d-]+)', response.text)
            
            if not vqd_match:
                print(f"Could not find vqd token for query: {query}")
                return []
            
            vqd = vqd_match.group(1)
            
            # Now make API request to get actual image data
            api_url = "https://duckduckgo.com/i.js"
            params = {
                'l': 'us-en',
                'o': 'json',
                'q': query,
                'vqd': vqd,
                'f': ',,,',
                'p': '1'
            }
            
            api_response = requests.get(api_url, headers=headers, params=params, timeout=10)
            api_response.raise_for_status()
            
            data = api_response.json()
            
            if 'results' in data:
                for result in data['results'][:max_images]:
                    if 'image' in result:
                        image_urls.append(result['image'])
            
            print(f"Found {len(image_urls)} images for query: {query}")
            return image_urls
            
        except Exception as e:
            print(f"Error searching DuckDuckGo for {query}: {e}")
            return []
    
    def search_google_images_fallback(self, query, max_images=50):
        """
        Fallback method using Google Images (less reliable due to anti-bot measures)
        
        Args:
            query (str): Search query
            max_images (int): Maximum number of image URLs to return
            
        Returns:
            list: List of image URLs
        """
        image_urls = []
        
        try:
            # Google Images search URL
            search_url = f"https://www.google.com/search?q={quote(query)}&tbm=isch&hl=en"
            
            headers = self.get_random_headers()
            
            response = requests.get(search_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find image elements
            img_tags = soup.find_all('img')
            
            for img in img_tags:
                src = img.get('src') or img.get('data-src')
                if src and src.startswith('http') and len(image_urls) < max_images:
                    image_urls.append(src)
            
            # Also look for data in script tags (Google stores image data in JSON)
            script_tags = soup.find_all('script')
            for script in script_tags:
                if script.string:
                    # Look for image URLs in the script content
                    urls = re.findall(r'https://[^"]*\.(?:jpg|jpeg|png|gif|webp)', script.string)
                    for url in urls:
                        if len(image_urls) < max_images:
                            image_urls.append(url)
            
            print(f"Found {len(image_urls)} images for query: {query}")
            return list(set(image_urls))  # Remove duplicates
            
        except Exception as e:
            print(f"Error searching Google Images for {query}: {e}")
            return []
    
    def search_unsplash_images(self, query, max_images=30):
        """
        Search Unsplash for high-quality images
        
        Args:
            query (str): Search query
            max_images (int): Maximum number of image URLs to return
            
        Returns:
            list: List of image URLs
        """
        image_urls = []
        
        try:
            search_url = f"https://unsplash.com/s/photos/{quote(query)}"
            headers = self.get_random_headers()
            
            response = requests.get(search_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find image elements
            img_tags = soup.find_all('img')
            
            for img in img_tags:
                src = img.get('src')
                if src and 'images.unsplash.com' in src and len(image_urls) < max_images:
                    # Get higher resolution version
                    if '?w=' in src:
                        src = src.split('?')[0] + '?w=800&h=600&fit=crop'
                    image_urls.append(src)
            
            print(f"Found {len(image_urls)} images from Unsplash for query: {query}")
            return image_urls
            
        except Exception as e:
            print(f"Error searching Unsplash for {query}: {e}")
            return []
    
    def search_images(self, query, count=50):
        """
        Search for images using multiple sources
        
        Args:
            query (str): Search query
            count (int): Number of images to fetch
            
        Returns:
            list: List of image URLs
        """
        all_urls = []
        
        # Try DuckDuckGo first (most reliable)
        print(f"Searching DuckDuckGo for: {query}")
        ddg_urls = self.search_duckduckgo_images(query, count // 2)
        all_urls.extend(ddg_urls)
        
        time.sleep(2)  # Be respectful
        
        # Try Unsplash for high-quality images
        print(f"Searching Unsplash for: {query}")
        unsplash_urls = self.search_unsplash_images(query, count // 3)
        all_urls.extend(unsplash_urls)
        
        time.sleep(2)
        
        # If we don't have enough, try Google Images as fallback
        if len(all_urls) < count:
            print(f"Searching Google Images for: {query}")
            google_urls = self.search_google_images_fallback(query, count - len(all_urls))
            all_urls.extend(google_urls)
        
        # Remove duplicates and return
        unique_urls = list(set(all_urls))
        return unique_urls[:count]
    
    def download_image(self, url, filepath):
        """
        Download an image from URL
        
        Args:
            url (str): Image URL
            filepath (Path): Local file path to save image
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            headers = self.get_random_headers()
            
            response = requests.get(url, headers=headers, timeout=15, stream=True)
            response.raise_for_status()
            
            # Check if it's actually an image
            content_type = response.headers.get('content-type', '')
            if not any(img_type in content_type.lower() for img_type in ['image', 'jpeg', 'png', 'gif', 'webp']):
                return False
            
            # Check file size (skip if too small or too large)
            content_length = response.headers.get('content-length')
            if content_length:
                size = int(content_length)
                if size < 1024 or size > 10 * 1024 * 1024:  # 1KB to 10MB
                    return False
            
            # Write image data
            with open(filepath, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            
            # Verify file was created and has content
            if filepath.exists() and filepath.stat().st_size > 1024:  # At least 1KB
                return True
            else:
                if filepath.exists():
                    filepath.unlink()  # Remove empty file
                return False
                
        except Exception as e:
            print(f"Error downloading {url}: {str(e)[:100]}...")
            if filepath.exists():
                filepath.unlink()  # Clean up partial download
            return False
    
    def get_file_extension(self, url):
        """
        Extract file extension from URL
        
        Args:
            url (str): Image URL
            
        Returns:
            str: File extension
        """
        parsed = urlparse(url)
        path = parsed.path.lower()
        
        # Common image extensions
        extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp']
        
        for ext in extensions:
            if ext in path:
                return ext
        
        return '.jpg'  # Default extension
    
    def create_unique_filename(self, base_name, url, directory):
        """
        Create a unique filename using hash
        
        Args:
            base_name (str): Base name for the file
            url (str): Image URL
            directory (Path): Target directory
            
        Returns:
            Path: Unique filepath
        """
        # Create hash from URL for uniqueness
        url_hash = hashlib.md5(url.encode()).hexdigest()[:8]
        extension = self.get_file_extension(url)
        
        filename = f"{base_name}_{url_hash}{extension}"
        return directory / filename
    
    def download_category_images(self, category, objects, images_per_object=50):
        """
        Download images for all objects in a category
        
        Args:
            category (str): Category name
            objects (list): List of object names
            images_per_object (int): Number of images to download per object
        """
        category_dir = self.base_dir / category
        category_dir.mkdir(exist_ok=True)
        
        print(f"\n{'='*60}")
        print(f"Processing Category: {category.upper().replace('_', ' ')}")
        print(f"{'='*60}")
        
        for i, obj in enumerate(objects, 1):
            print(f"\n[{i}/{len(objects)}] Processing: {obj}")
            print("-" * 40)
            
            # Create object directory
            obj_clean = obj.replace(" ", "_").replace("/", "_")
            obj_dir = category_dir / obj_clean
            obj_dir.mkdir(exist_ok=True)
            
            # Check how many images we already have
            existing_images = len(list(obj_dir.glob("*")))
            if existing_images >= images_per_object:
                print(f"Already have {existing_images} images for {obj}, skipping...")
                continue
            
            needed = images_per_object - existing_images
            print(f"Need {needed} more images (have {existing_images})")
            
            # Search for images
            image_urls = self.search_images(obj, count=needed * 3)  # Get extra in case some fail
            
            if not image_urls:
                print(f"No images found for {obj}")
                continue
            
            # Download images
            downloaded = 0
            failed = 0
            
            for j, url in enumerate(image_urls):
                if downloaded >= needed:
                    break
                
                filepath = self.create_unique_filename(obj_clean, url, obj_dir)
                
                # Skip if file already exists
                if filepath.exists():
                    continue
                
                print(f"  Downloading {j+1}/{len(image_urls)}: {url[:60]}...")
                
                if self.download_image(url, filepath):
                    downloaded += 1
                    if downloaded % 5 == 0:
                        print(f"  ✓ Downloaded {downloaded}/{needed} images")
                else:
                    failed += 1
                
                # Be respectful with requests
                time.sleep(random.uniform(1, 3))
            
            total_images = existing_images + downloaded
            print(f"\n✓ Completed {obj}: {total_images} total images ({downloaded} new, {failed} failed)")
    
    def create_dataset(self, images_per_object=50):
        """
        Create the complete dataset
        
        Args:
            images_per_object (int): Number of images to download per object
        """
        print("Image Dataset Creator using Web Scraping")
        print("=" * 45)
        print(f"Target: {images_per_object} images per object")
        print(f"Dataset directory: {self.base_dir.absolute()}")
        print(f"Total objects: {sum(len(objects) for objects in self.objects.values())}")
        print(f"Estimated total images: {sum(len(objects) for objects in self.objects.values()) * images_per_object}")
        
        start_time = time.time()
        
        for category, objects in self.objects.items():
            try:
                self.download_category_images(category, objects, images_per_object)
            except KeyboardInterrupt:
                print("\n\n⚠️  Download interrupted by user")
                break
            except Exception as e:
                print(f"\n❌ Error processing category {category}: {e}")
                continue
            
            # Longer pause between categories
            print(f"\nPausing before next category...")
            time.sleep(5)
        
        end_time = time.time()
        print(f"\n{'='*60}")
        print(f"Dataset creation completed in {(end_time - start_time)/60:.1f} minutes")
        
        # Print summary
        self.print_dataset_summary()
    
    def print_dataset_summary(self):
        """Print a summary of the created dataset"""
        print(f"\n{'='*60}")
        print("DATASET SUMMARY")
        print("="*60)
        
        total_images = 0
        
        for category, objects in self.objects.items():
            category_dir = self.base_dir / category
            if not category_dir.exists():
                continue
            
            print(f"\n📁 {category.upper().replace('_', ' ')}:")
            category_total = 0
            
            for obj in objects:
                obj_clean = obj.replace(" ", "_").replace("/", "_")
                obj_dir = category_dir / obj_clean
                
                if obj_dir.exists():
                    count = len([f for f in obj_dir.glob("*") if f.is_file()])
                    print(f"  • {obj}: {count} images")
                    category_total += count
                else:
                    print(f"  • {obj}: 0 images")
            
            print(f"  Subtotal: {category_total} images")
            total_images += category_total
        
        print(f"\n🎯 TOTAL DATASET SIZE: {total_images} images")
        print(f"📍 Dataset location: {self.base_dir.absolute()}")
        print(f"\n💡 Your dataset is ready for training!")


def main():
    """
    Main function to create the dataset
    """
    print("🖼️  Image Dataset Creator for Object Recognition")
    print("=" * 50)
    print("This tool will scrape images from multiple sources including:")
    print("• DuckDuckGo (primary source)")
    print("• Unsplash (high-quality images)")
    print("• Google Images (fallback)")
    print("\n⚠️  Note: Web scraping can be slow and some requests may fail.")
    print("This is normal - the script will continue with available images.\n")
    
    # Get number of images per object
    try:
        images_per_object = int(input("Enter number of images per object (default 30): ") or "30")
    except ValueError:
        images_per_object = 30
    
    if images_per_object > 100:
        print("⚠️  Warning: Large numbers may take a very long time and increase chance of being blocked.")
        confirm = input("Continue anyway? (y/N): ").lower()
        if confirm != 'y':
            return
    
    print(f"\n🚀 Starting dataset creation with {images_per_object} images per object...")
    
    # Create dataset
    creator = ImageDatasetCreator()
    creator.create_dataset(images_per_object)
    
    print("\n✅ Dataset creation finished!")
    print("📚 You can now use this dataset to train your vision model.")
    print("\n💡 Tips:")
    print("• Review downloaded images and remove any irrelevant ones")
    print("• Consider data augmentation techniques for better training")
    print("• Split your data into train/validation/test sets")


if __name__ == "__main__":
    main()