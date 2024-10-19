from flask import Flask, request, jsonify
from PIL import Image
import io
import base64

app = Flask(__name__)

@app.route('/process', methods=['POST'])
def process_field():
    # Parse the incoming JSON data
    data = request.get_json()

    # Get the field name, coordinates, and base64 encoded image from the request
    field_name = data.get('fieldName')
    coordinates = data.get('coordinates')
    image_base64 = data.get('image')

    # Decode the base64 image
    image_data = base64.b64decode(image_base64)
    image = Image.open(io.BytesIO(image_data))

    # Get the field coordinates from the request
    x = coordinates['x']
    y = coordinates['y']
    width = coordinates['width']
    height = coordinates['height']

    # Crop the image using the coordinates
    cropped_image = image.crop((x, y, x + width, y + height))

    # Here you would perform any processing on the cropped image (e.g., OCR, ML model, etc.)
    # For now, we'll mock a simple result.
    mock_result = f"Extracted text from {field_name}"

    # Return the processed result as a JSON response
    return jsonify({
        'fieldName': field_name,
        'extractedText': mock_result
    })

if __name__ == '__main__':
    app.run(debug=True, port=5000)
